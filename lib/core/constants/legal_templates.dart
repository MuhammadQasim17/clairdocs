class LegalTemplates {
  LegalTemplates._();

  static const String formalDisputeLetterHeader = '''
NOTICE OF FORMAL BILLING DISCREPANCY & DISPUTE
Date: {{DATE}}
To: {{VENDOR_NAME}}
Attention: {{VENDOR_ATTENTION}}
Reference: Contract #{{CONTRACT_ID}} / Invoice #{{INVOICE_NUMBER}}
''';

  static const String formalReservationOfRights = '''
Please be advised that pursuant to Section {{CLAUSE_NUMBER}} of the governing Agreement, payment of the undisputed amount of {{UNDISPUTED_AMOUNT}} is being processed. The disputed balance of {{DISPUTED_AMOUNT}} is withheld pending reconciliation. All rights and remedies remain expressly reserved.
''';
}

