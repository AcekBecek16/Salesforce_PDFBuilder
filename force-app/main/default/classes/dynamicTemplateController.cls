public with sharing class dynamicTemplateController {
  public PDF_Template__c template { get; set; }
  public SObject record { get; set; }
  public String renderedBody { get; set; }
  Set<String> fields;

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

    if (template.Insert_Fields__c != null) {
      List<String> fieldList = template.Insert_Fields__c
        .replace('[', '')
        .replace(']', '')
        .replace('"', '')
        .deleteWhitespace()
        .split(',');

      fields = new Set<String>(fieldList);
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

    renderedBody = processMergeFields(template.Body__c, record);
  }

  private String processMergeFields(String body, SObject record) {
    System.debug('record: ' + record);
    System.debug('fields: ' + fields);
    Map<String, Object> fieldMap = record.getPopulatedFieldsAsMap();
    for (String fieldName : fieldMap.keySet()) {
      String token = '{!Record.' + fieldName + '}';
      String value = String.valueOf(fieldMap.get(fieldName));

      system.debug('token => ' + token + ' : Value => ' + value);

      body = body.replace(token, value == null || value == '' ? '' : value);
    }
    for (String fieldUmap : fields) {
      String token = '{!Record.' + fieldUmap + '}';
      system.debug('token => ' + token);

      body = body.replace(token, '');
    }
    return body;
  }
}