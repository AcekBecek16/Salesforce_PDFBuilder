# Salesforce PDF Builder 📄

A comprehensive Salesforce solution for creating dynamic PDF documents with merge fields, rich text editing, and template management. This package provides a complete PDF generation system with Lightning Web Components (LWC) and Apex controllers.

## 🚀 Features

### Core Functionality
- **Dynamic PDF Templates**: Create and manage reusable PDF templates with merge fields
- **Rich Text Editor**: Built-in WYSIWYG editor with comprehensive formatting options
- **Dynamic Field Insertion**: Automatically populate PDFs with Salesforce record data
- **Multi-Object Support**: Works with any Salesforce standard or custom object
- **Live Preview**: Real-time preview of PDF templates before generation
- **Smart Search**: Enhanced search functionality with multi-field support

### Technical Features
- **Performance Optimized**: Field caching and efficient SOQL queries
- **Security First**: Input validation and SOQL injection protection
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Mobile Responsive**: Lightning Web Components optimized for all devices

## 📦 Package Contents

### Lightning Web Components
- `pdfBuilder` - Main template builder component
- `dynamicSearch` - Enhanced search functionality
- `generatePdf` - PDF generation interface
- `modalGeneratePDF` - Modal for PDF generation
- `previewDynamicPDF` - PDF preview modal

### Apex Classes
- `pdfBuilderController` - Main controller with field management and search
- `dynamicTemplateController` - Template processing and dynamic content
- `generatePdfController` - PDF generation logic

### Custom Objects
- `PDF_Template__c` - Stores PDF template configurations
  - `Body__c` - Rich text template content
  - `Related_Object__c` - Associated Salesforce object
  - `Insert_Fields__c` - Merge field configurations

### Additional Components
- Permission sets for user access management
- Custom application and tabs
- Flexible page layouts
- Static resources (headers/footers)

## 🛠️ Installation

### Prerequisites
- Salesforce DX CLI installed
- Dev Hub enabled in your Salesforce org
- VSCode with Salesforce extensions (recommended)

### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/AcekBecek16/Salesforce_PDFBuilder.git
   cd SFDC_PDFBuilder
   ```

2. **Authenticate with your org**
   ```bash
   sf org login web --alias your-org-alias
   ```

3. **Deploy to your org**
   ```bash
   sf project deploy start --target-org your-org-alias
   ```

4. **Assign permission set**
   ```bash
   sf org assign permset --name PDF_Builder_Permission --target-org your-org-alias
   ```

## 📋 Setup Instructions

### Post-Deployment Configuration

1. **Navigate to the PDF Builder App**
   - Go to App Launcher → PDF Builder
   - Access the PDF Templates tab

2. **Create Your First Template**
   - Click "New" on the PDF Template list view
   - Select the related Salesforce object
   - Use the rich text editor to design your template
   - Insert merge fields using the field picker

3. **Configure Object Permissions**
   - Ensure users have access to relevant Salesforce objects
   - Verify field-level security settings

## 💡 Usage Guide

### Creating a PDF Template

1. **Select Object**: Choose the Salesforce object for your template
2. **Design Template**: Use the rich text editor with formatting options:
   - Text formatting (bold, italic, underline)
   - Lists and indentation
   - Tables and headers
   - Colors and backgrounds
   - Images and links

3. **Insert Merge Fields**: 
   - Position cursor where you want the field
   - Select field from the dropdown
   - Support for lookup fields and related objects

4. **Preview**: Test your template with actual record data
5. **Generate**: Create PDFs for specific records

### Merge Field Syntax
Merge fields use the format: `{!Record.FieldName}`
For related objects: `{!Record.RelatedObject.FieldName}`

## 🔧 Technical Architecture

### Apex Controllers

**pdfBuilderController**
- Field metadata retrieval with caching
- Secure record search functionality
- Multi-field search capabilities
- Input validation and security

**dynamicTemplateController**
- Template processing
- Merge field resolution
- Dynamic content generation

**generatePdfController**
- PDF generation coordination
- Template rendering
- Output formatting

### Security Features
- SOQL injection prevention
- Object and field accessibility checks
- Input sanitization
- User permission validation

## 🚀 Advanced Configuration

### Custom Object Integration
To use with custom objects:
1. Ensure object is accessible to users
2. Configure field-level security
3. Update permission sets as needed

### Performance Optimization
- Field definitions are cached for improved performance
- Efficient SOQL queries with selective fields
- Lazy loading of lookup relationships

## 📊 API Version
- Salesforce API Version: **62.0**
- Lightning Web Components API
- Modern Apex patterns

## 🛡️ Security Considerations

- All user inputs are validated and sanitized
- SOQL queries use bind variables to prevent injection
- Object and field accessibility checks
- Proper sharing rules enforcement

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in the GitHub repository
- Check the Salesforce Developer Documentation
- Review Salesforce DX best practices

## 🔗 Resources

- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Lightning Web Components Documentation](https://developer.salesforce.com/docs/component-library/overview/components)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)

---

**Built with ❤️ for the Salesforce Community**
