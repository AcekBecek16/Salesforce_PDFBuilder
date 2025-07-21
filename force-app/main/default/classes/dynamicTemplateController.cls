public with sharing class dynamicTemplateController {
  public PDF_Template__c template { get; set; }
  public SObject record { get; set; }
  public String renderedBody { get; set; }

  public dynamicTemplateController() {
    String templateId = ApexPages.currentPage()
      .getParameters()
      .get('templateId');

    String recordId = ApexPages.currentPage().getParameters().get('recordId');

    if (!String.isBlank(templateId)) {
      template = [
        SELECT Id, Body__c, Related_Object__c, Insert_Fields__c
        FROM PDF_Template__c
        WHERE Id = :templateId
        LIMIT 1
      ];
    }

    Set<String> fields = new Set<String>();
    String body = template.Body__c;
    if (template.Insert_Fields__c != null) {
      List<Object> fieldList = (List<Object>) JSON.deserializeUntyped(
        template.Insert_Fields__c
      );
      for (Object insertField : fieldList) {
        Map<String, Object> insertFieldMap = (Map<String, Object>) insertField;
        System.debug('field : ' + insertFieldMap.get('fieldName'));
        String fieldName = String.valueOf(insertFieldMap.get('fieldName'));
        String fieldType = String.valueOf(insertFieldMap.get('fieldType'));
        String newFieldName = '';

        if (fieldType == 'id') {
          newFieldName = fieldName.replace('__c', '__r.Name');
          if (newFieldName != '') {
            fields.add(newFieldName);
            body = body.replace(fieldName, newFieldName);
          }
        } else {
          fields.add(fieldName);
        }
      }
    } else {
      fields.add('Name');
    }

    String objectApiName = template.Related_Object__c;
    String query =
      'SELECT ' +
      String.join(fields, ',') +
      ' FROM ' +
      objectApiName +
      ' WHERE Id = \'' +
      recordId +
      '\'';
    System.debug(query);
    record = Database.query(query);

    renderedBody = processMergeFields(body, record);
  }

  private String processMergeFields(String body, SObject record) {
    if (body == null || record == null) {
      return body;
    }

    // Deserialize record fields ke Map<String, Object>
    Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(
      JSON.serialize(record.getPopulatedFieldsAsMap())
    );

    // Cari semua token merge field dalam body: {!Record.<field>}
    Pattern p = Pattern.compile('\\{!Record\\.([a-zA-Z0-9_\\.]+)\\}');
    Matcher m = p.matcher(body);

    Set<String> tokens = new Set<String>();
    while (m.find()) {
      tokens.add(m.group(1));
    }

    // Gantikan setiap token dengan nilai dari record
    for (String token : tokens) {
      String replacement = getFieldValueFromMap(token, fieldMap);
      if (replacement == null) {
        replacement = '';
      }
      body = body.replace('{!Record.' + token + '}', replacement);
    }

    return body;
  }
  private String getFieldValueFromMap(String token, Map<String, Object> mapp) {
    if (token == null || token == '') {
      return null;
    }

    if (!token.contains('.')) {
      Object val = mapp.get(token);
      return val != null ? String.valueOf(val) : null;
    } else {
      Integer dotIndex = token.indexOf('.');
      String parentField = token.substring(0, dotIndex);
      String childField = token.substring(dotIndex + 1);

      Object relatedObj = mapp.get(parentField);
      if (relatedObj != null && relatedObj instanceof Map<String, Object>) {
        Map<String, Object> relatedMap = (Map<String, Object>) relatedObj;
        return getFieldValueFromMap(childField, relatedMap);
      } else {
        return null;
      }
    }
  }
}