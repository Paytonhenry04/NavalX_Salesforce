@JsonAccess(serializable='always' deserializable='always')
public class DatacloudSQLExecuter {
  public class SecurityException extends Exception {}
  // Input class, this will be used by the agent to pass the OSC output to the
  // main invocable method.
  public class Input {
    @InvocableVariable(label = 'SQL String') public String sqlString;
  }
  public class Output {
    @InvocableVariable(label = 'JSON Result') public String json;
    @InvocableVariable(label = 'Error (if any)') public String error;
  }
  @InvocableMethod(label = 'Execute Datacloud SQL')
  public static List<Output> executeOscSql(List<Input> inputs) {
    List<Output> outputs = new List<Output>();
    Output out = new Output();
    outputs.add(out);
    ConnectApi.QuerySqlInput sqlQuery = new ConnectApi.QuerySqlInput();
    // This grabs the first word from the SQL Query input.
    String query =
        inputs[0].sqlString != null ? inputs[0].sqlString.trim() : '';
    String upperQuery = query.toUpperCase();
    try {
      // Use the first word from the SQL Query to make sure there are no DELETE
      // or any other harmful queries.
      if (upperQuery.startsWith('SELECT') || upperQuery.startsWith('WITH')) {
        sqlQuery.sql = inputs[0].sqlString;
      } else {
        throw new SecurityException('Only SQL SELECT Queries are allowed.');
      }
    } catch (Exception e) {
      System.debug('Error: ' + e.getMessage());
    }
    try {
      ConnectApi.QuerySqlOutput queryResults =
          ConnectApi.CdpQuery.querySql(sqlQuery, 'sample_workload', 'default');
      if (queryResults != null && !queryResults.dataRows.isEmpty()) {
        System.debug(
            'Processing ' + queryResults.dataRows.size() + ' result rows.');
        List<Map<String, Object>> rowsWithHeaders =
            new List<Map<String, Object>>();
        List<String> colNames = new List<String>();
        for (ConnectApi.QuerySqlMetadataItem m : queryResults.metadata) {
          colNames.add(m.name);
        }
        for (ConnectApi.QuerySqlRow r : queryResults.dataRows) {
          Map<String, Object> rowMap = new Map<String, Object>();
          for (Integer i = 0; i < colNames.size(); i++) {
            String colName = colNames[i];
            if (colName.endsWith('_c__c')) {
              colName = colName.replace('_c__c', '__c');
            }
            if (colName.endsWith('__c')) {
              colName = colName.replace('__c', '');
            }
            rowMap.put(colName, r.row[i]);
          }
          rowsWithHeaders.add(rowMap);
        }
        String jsonResult = JSON.serialize(rowsWithHeaders);
        outputs[0].json = jsonResult;
      } else {
        System.debug('Data Cloud query returned no results');
        outputs[0].error = 'No results, only SELECT queries are allowed.';
      }
    } catch (Exception e) {
      outputs[0].error = 'Data Cloud query failed: ' + e.getMessage();
      return outputs;
    }
    return outputs;
  }
}