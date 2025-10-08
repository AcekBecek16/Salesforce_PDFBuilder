public with sharing class dynamicTemplateController {
  public PDF_Template__c template { get; private set; }
  public SObject record { get; private set; }
  public String renderedBody { get; private set; }

  public dynamicTemplateController() {
    try {
      String templateId = ApexPages.currentPage()
        .getParameters()
        .get('templateId');
      String recordId = ApexPages.currentPage().getParameters().get('recordId');
      String nomorSurat =
        '' + ApexPages.currentPage().getParameters().get('nomorSurat');

      initializeTemplate(templateId);
      Set<String> requiredFields = parseInsertFields(template);

      if (String.isBlank(template.Related_Object__c)) {
        throw new CustomException('Template missing Related Object.');
      }

      String objectApiName = template.Related_Object__c;
      String[] fieldList = new List<String>(requiredFields);

      record = queryRecord(objectApiName, fieldList, recordId);
      renderedBody = renderTemplateBody(template.Body__c, record, nomorSurat);
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Error initializing template: ' + e.getMessage()
      );
      ApexPages.addMessage(
        new ApexPages.Message(
          ApexPages.Severity.ERROR,
          'An error occurred while loading the template.'
        )
      );
    }
  }

  private void initializeTemplate(String templateId) {
    if (String.isBlank(templateId)) {
      throw new CustomException('Template ID is required.');
    }

    template = [
      SELECT Id, Body__c, Related_Object__c, Insert_Fields__c
      FROM PDF_Template__c
      WHERE Id = :templateId
      LIMIT 1
    ];
  }

  private Set<String> parseInsertFields(PDF_Template__c template) {
    Set<String> fields = new Set<String>();

    if (String.isBlank(template.Insert_Fields__c)) {
      fields.add('Name');
      return fields;
    }

    try {
      List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(
        template.Insert_Fields__c
      );
      for (Object item : fieldList) {
        if (item instanceof Map<String, Object>) {
          Map<String, Object> fieldEntry = (Map<String, Object>) item;
          String fieldName = String.valueOf(fieldEntry.get('fieldName'));
          String fieldType = String.valueOf(fieldEntry.get('fieldType'));

          if (fieldType == 'id') {
            String relatedNameField = fieldName.replace('__c', '__r.Name');
            fields.add(relatedNameField);
          } else {
            fields.add(fieldName);
          }
        }
      }
    } catch (Exception e) {
      throw new CustomException(
        'Failed to parse Insert_Fields__c: ' + e.getMessage()
      );
    }

    return fields;
  }

  private SObject queryRecord(
    String objectApiName,
    List<String> fieldList,
    String recordId
  ) {
    String fields = String.join(fieldList, ', ');

    String filter = '';
    if (!String.isBlank(recordId)) {
      filter = ' WHERE Id = :recordId ';
    }

    // Use proper bind variable
    String query =
      'SELECT ' +
      fields +
      ' FROM ' +
      objectApiName +
      filter +
      ' LIMIT 1';

    List<SObject> results = Database.query(query);
    return results.isEmpty() ? null : results[0];
  }

  private String renderTemplateBody(
    String body,
    SObject record,
    String nomorSurat
  ) {
    if (String.isBlank(body) || record == null) {
      return body;
    }

    Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(record.getPopulatedFieldsAsMap())
    );
    // System.debug(
    //   'Serialize: ' + JSON.serialize(record.getPopulatedFieldsAsMap())
    // );
    return replaceMergeFields(body, fieldMap, nomorSurat);
  }

  private String replaceMergeFields(
    String body,
    Map<String, Object> fieldMap,
    String nomorSurat
  ) {
    Pattern p = Pattern.compile('\\{!Record\\.([a-zA-Z0-9_\\.]+)\\}');
    Matcher m = p.matcher(body);
    while (m.find()) {
      String fullToken = m.group(0);
      String token = m.group(1);
      Object value = getFieldValueFromMap(token, fieldMap);
      if (value == null) {
        value = '';
      } else if (value instanceof Datetime) {
        value = convertToIndonesianDate((Datetime) value);
      } else if (value instanceof String) {
        String stringValue = (String) value;
        if (isValidISODate(stringValue)) {
          try {
            Datetime dt = convertISOToDate(stringValue);
            value = convertToIndonesianDate(dt);
          } catch (Exception e) {
            // Keep original value if parsing fails
          }
        }
      }
      System.debug(
        'Replacing token: ' +
          fullToken +
          ' with value: ' +
          String.valueOf(value)
      );
      body = body.replace(fullToken, String.valueOf(value));
    }
    body = body.replace('[jenis_surat]', nomorSurat);
    return body;
  }

  private Datetime convertISOToDate(String isoDateString) {
    // Remove the 'Z' and parse manually, or use JSON deserialization
    try {
      // Method 1: JSON deserialization (most reliable)
      return (Datetime) JSON.deserialize(
        '"' + isoDateString + '"',
        Datetime.class
      );
    } catch (Exception e) {
      // Fallback: manual parsing
      return parseISODateManually(isoDateString);
    }
  }

  private Datetime parseISODateManually(String isoDateString) {
    // Remove the 'Z' at the end
    String cleanDate = isoDateString.replace('Z', '');
    // Parse the components
    List<String> dateParts = cleanDate.split('T');
    List<String> dateComponent = dateParts[0].split('-');
    List<String> timeComponent = dateParts[1].split(':');
    List<String> secondsComponent = timeComponent[2].split('\\.');

    Integer year = Integer.valueOf(dateComponent[0]);
    Integer month = Integer.valueOf(dateComponent[1]);
    Integer day = Integer.valueOf(dateComponent[2]);
    Integer hour = Integer.valueOf(timeComponent[0]);
    Integer minute = Integer.valueOf(timeComponent[1]);
    Integer second = Integer.valueOf(secondsComponent[0]);

    return Datetime.newInstance(year, month, day, hour, minute, second);
  }

  private String convertToIndonesianDate(Datetime dt) {
    Integer day = Integer.valueOf(dt.format('dd'));
    String month = dt.format('MMMM');
    Integer year = Integer.valueOf(dt.format('yyyy'));
    String timeStr = dt.format('HH:mm');
    return 'tanggal ' + day + ' ' + month + ' ' + year + ', pukul ' + timeStr;
  }

  private Boolean isValidISODate(String dateStr) {
    return dateStr != null && dateStr.contains('T') && dateStr.endsWith('Z');
  }

  private String getFieldValueFromMap(String token, Map<String, Object> mapp) {
    if (token == null || token == '')
      return null;

    String[] parts = token.split('\\.');
    Map<String, Object> currentMap = mapp;

    for (Integer i = 0; i < parts.size(); i++) {
      String part = parts[i];

      if (i == parts.size() - 1) {
        // Final level - return string value
        Object val = currentMap.get(part);
        return val != null ? String.valueOf(val) : null;
      } else {
        // Navigate deeper into nested map
        Object nested = currentMap.get(part);
        if (nested instanceof Map<String, Object>) {
          currentMap = (Map<String, Object>) nested;
        } else {
          return null;
        }
      }
    }

    return null;
  }

  // Custom Exception Class
  public class CustomException extends Exception {
  }
}
