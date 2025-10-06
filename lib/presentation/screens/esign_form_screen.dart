import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/mcp_surepass_service.dart';

class ESignFormScreen extends StatefulWidget {
  const ESignFormScreen({super.key});

  @override
  State<ESignFormScreen> createState() => _ESignFormScreenState();
}

class _ESignFormScreenState extends State<ESignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _isLoading = false;
  String? _esignUrl;
  String? _transactionId;
  final MCPSurePassService _esignService = MCPSurePassService();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _proceedToEsign() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the complete eSign flow method - handles initialization and PDF upload
      final result = await _esignService.completeESignFlow(
        fullName: _nameController.text,
        userEmail: _emailController.text,
        mobileNumber: _mobileController.text,
        pdfUrl: 'https://d3b8wlkco88yji.cloudfront.net/utils/dummy-pdf.pdf',
        callbackUrl: 'https://yourapp.com/esign/callback',
      );

      if (result['success'] == true) {
        _esignUrl = result['esign_url'];
        _transactionId = result['client_id'];
        _showEsignWebView();
      } else {
        _showErrorDialog('Failed to initiate eSign: ${result['message']}');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showEsignWebView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EsignWebViewScreen(
          esignUrl: _esignUrl!,
          onSuccess: _onEsignSuccess,
        ),
      ),
    );
  }

  void _onEsignSuccess(String signedDocumentUrl) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EsignSuccessScreen(
          documentUrl: signedDocumentUrl,
          transactionId: _transactionId,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _fillMyData() {
    setState(() {
      _nameController.text = 'Rishabh Singh';
      _emailController.text = 'singhrishabh1672@gmail.com';
      _mobileController.text = '7587136215';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form filled with your data!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await _esignService.testApiConnectivity();
      final message = isConnected
          ? '✅ API Connection Test Successful!\n\nSurePass API is reachable and responding.'
          : '❌ API Connection Test Failed!\n\nUnable to reach SurePass API. Please check your internet connection.';

      _showErrorDialog(message);
    } catch (e) {
      _showErrorDialog('❌ API Connection Test Failed!\n\nError: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Signature Form'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi_find),
            onPressed: _testApiConnection,
            tooltip: 'Test API Connection',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please fill in your details for e-signature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Full Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // User Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'User Email *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your mobile number';
                  }
                  if (value.length != 10) {
                    return 'Please enter a valid 10-digit mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Proceed to E-sign Button
              ElevatedButton(
                onPressed: _isLoading ? null : _proceedToEsign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Proceed to E-Sign',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fillMyData,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        tooltip: 'Fill My Data',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class EsignWebViewScreen extends StatefulWidget {
  final String esignUrl;
  final Function(String) onSuccess;

  const EsignWebViewScreen({
    super.key,
    required this.esignUrl,
    required this.onSuccess,
  });

  @override
  State<EsignWebViewScreen> createState() => _EsignWebViewScreenState();
}

class _EsignWebViewScreenState extends State<EsignWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    print('Loading e-sign URL: ${widget.esignUrl}');
    _loadUrl();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _loadUrl() async {
    print('Initializing WebView with URL: ${widget.esignUrl}');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1')
      ..enableZoom(true)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            // Set a longer timeout for e-signature pages
            _timeoutTimer?.cancel();
            _timeoutTimer = Timer(const Duration(seconds: 60), () {
              if (mounted && _isLoading) {
                print('WebView timeout after 60 seconds');
                setState(() {
                  _isLoading = false;
                  _errorMessage =
                      'Request timed out. The e-signature page is taking too long to load.';
                });
              }
            });
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            print('Error code: ${error.errorCode}');
            print('Error type: ${error.errorType}');
            _timeoutTimer?.cancel();
            setState(() {
              _isLoading = false;
              _errorMessage = _getErrorMessage(error);
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request to: ${request.url}');

            // Check for completion indicators
            if (request.url.contains('success') ||
                request.url.contains('completed') ||
                request.url.contains('done') ||
                request.url.contains('finished')) {
              print('E-signature completed! URL: ${request.url}');
              widget.onSuccess(request.url);
              return NavigationDecision.prevent;
            }

            // Allow all other navigation
            return NavigationDecision.navigate;
          },
        ),
      );

    print('Loading URL in WebView...');
    try {
      await _controller.loadRequest(Uri.parse(widget.esignUrl));
    } catch (e) {
      print('Error loading URL: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load URL: $e';
      });
    }
  }

  String _getErrorMessage(WebResourceError error) {
    if (error.description.contains('ERR_CONNECTION_RESET') ||
        error.description.contains('connection was reset')) {
      return 'Connection was reset by the server. Please try again.';
    } else if (error.description.contains('network connection was lost') ||
        error.description.contains('network error')) {
      return 'Network connection lost. Please check your internet connection.';
    } else if (error.description.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (error.description.contains('SSL') ||
        error.description.contains('certificate')) {
      return 'Security certificate error. Please try again.';
    } else if (error.description.contains('ERR_NAME_NOT_RESOLVED')) {
      return 'Cannot resolve server address. Please check your internet connection.';
    } else {
      return 'Failed to load page: ${error.description}';
    }
  }

  void _retryLoad() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    print('Retrying load...');
    _loadUrl();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Signature Process'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('Reloading WebView...');
              setState(() {
                _errorMessage = null;
                _isLoading = true;
              });
              _loadUrl();
            },
            tooltip: 'Refresh Page',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () async {
              try {
                final uri = Uri.parse(widget.esignUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot open URL in external browser'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening URL: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            tooltip: 'Open in External Browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Page',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          final uri = Uri.parse(widget.esignUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Cannot open URL in external browser'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening URL: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Browser'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && _errorMessage == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading e-signature page...'),
                ],
              ),
            ),
          // Manual completion button (floating)
          if (!_isLoading && _errorMessage == null)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton.extended(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Complete E-Signature'),
                      content: const Text(
                        'Have you completed the e-signature process?\n\n'
                        'Click "Yes" to proceed to the success screen.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('No, Continue'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onSuccess(widget.esignUrl);
                          },
                          child: const Text('Yes, I\'m Done'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Done'),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}

class EsignSuccessScreen extends StatelessWidget {
  final String documentUrl;
  final String? transactionId;

  const EsignSuccessScreen({
    super.key,
    required this.documentUrl,
    this.transactionId,
  });

  Future<void> _downloadDocument(BuildContext context) async {
    try {
      final esignService = MCPSurePassService();

      // Get signed document info first
      final documentInfo =
          await esignService.getSignedDocument(transactionId ?? '');

      if (documentInfo['success'] == true) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/signed_document.pdf';

        // Download the signed document
        await esignService.downloadSignedDocument(
            transactionId ?? '', filePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to get signed document: ${documentInfo['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Signature Success'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const Text(
                'You have successfully signed the document!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your signed document is ready for download.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _downloadDocument(context),
                icon: const Icon(Icons.download),
                label: const Text('Download Signed Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
