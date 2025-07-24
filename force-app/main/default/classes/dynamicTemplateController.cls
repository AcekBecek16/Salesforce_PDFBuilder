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

      initializeTemplate(templateId);
      Set<String> requiredFields = parseInsertFields(template);

      if (String.isBlank(template.Related_Object__c)) {
        throw new CustomException('Template missing Related Object.');
      }

      String objectApiName = template.Related_Object__c;
      String[] fieldList = new List<String>(requiredFields);

      record = queryRecord(objectApiName, fieldList, recordId);
      renderedBody = renderTemplateBody(template.Body__c, record);
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

  private String renderTemplateBody(String body, SObject record) {
    if (String.isBlank(body) || record == null) {
      return body;
    }

    Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(record.getPopulatedFieldsAsMap())
    );
    return replaceMergeFields(body, fieldMap);
  }

  private String replaceMergeFields(String body, Map<String, Object> fieldMap) {
    Pattern p = Pattern.compile('\\{!Record\\.([a-zA-Z0-9_\\.]+)\\}');
    Matcher m = p.matcher(body);

    while (m.find()) {
      String fullToken = m.group(0); // e.g., {!Record.Contact__r.Name}
      String token = m.group(1); // e.g., Contact__r.Name
      String value = getFieldValueFromMap(token, fieldMap);

      if (value == null) {
        value = '';
      }

      body = body.replace(fullToken, value); // Safely replace full token
    }

    return body;
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
