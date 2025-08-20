import 'package:flutter/material.dart';
import 'package:ia_tracking/ia_tracking.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _statusMessage = 'Ready';

  // Form demo state
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  String _selectedCategory = 'Electronics';

  // Search demo state
  List<String> _searchResults = [];

  final List<String> _categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home & Garden',
    'Sports',
    'Toys',
  ];

  final Map<String, List<String>> _categoryItems = {
    'Electronics': ['Smartphone', 'Laptop', 'Headphones', 'Camera', 'Tablet'],
    'Clothing': ['T-Shirt', 'Jeans', 'Dress', 'Jacket', 'Sneakers'],
    'Books': ['Fiction', 'Science', 'History', 'Biography', 'Mystery'],
    'Home & Garden': ['Sofa', 'Table', 'Plants', 'Lamp', 'Curtains'],
    'Sports': [
      'Football',
      'Basketball',
      'Tennis Racket',
      'Running Shoes',
      'Yoga Mat'
    ],
    'Toys': [
      'Action Figure',
      'Board Game',
      'Puzzle',
      'Doll',
      'Building Blocks'
    ],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _trackScreenView();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _trackTabChange();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _trackScreenView() async {
    try {
      await IaTracker.instance.trackScreenView('DemoScreen');
    } catch (e) {
      _updateStatus('Failed to track screen view: $e');
    }
  }

  Future<void> _trackTabChange() async {
    try {
      final tabNames = ['Buttons', 'Forms', 'Search', 'Navigation'];
      final tabName = tabNames[_tabController.index];

      await IaTracker.instance.trackCustomEvent(
        'tab_changed',
        'DemoScreen',
        elementId: 'tab_controller',
        properties: {
          'tab_index': _tabController.index,
          'tab_name': tabName,
        },
      );

      _updateStatus('Tracked tab change to $tabName');
    } catch (e) {
      _updateStatus('Failed to track tab change: $e');
    }
  }

  Future<void> _trackButtonTap(String buttonId,
      {Map<String, dynamic>? properties}) async {
    try {
      await IaTracker.instance.trackButtonTap(buttonId, 'DemoScreen');

      if (properties != null) {
        await IaTracker.instance.trackCustomEvent(
          'button_interaction',
          'DemoScreen',
          elementId: buttonId,
          properties: properties,
        );
      }

      _updateStatus('Tracked button tap: $buttonId');
    } catch (e) {
      _updateStatus('Failed to track button tap: $e');
    }
  }

  Future<void> _performSearch(String query) async {
    try {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      // Simulate search
      final results = <String>[];
      for (final category in _categories) {
        for (final item in _categoryItems[category] ?? []) {
          if (item.toLowerCase().contains(query.toLowerCase())) {
            results.add('$item (in $category)');
          }
        }
      }

      setState(() {
        _searchResults = results;
      });

      // Track search
      await IaTracker.instance.trackSearch(
        query,
        'DemoScreen',
        resultsCount: results.length,
      );

      _updateStatus('Search tracked: "$query" (${results.length} results)');
    } catch (e) {
      _updateStatus('Failed to track search: $e');
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await IaTracker.instance.trackCustomEvent(
          'form_submitted',
          'DemoScreen',
          elementId: 'demo_form',
          properties: {
            'name_length': _nameController.text.length,
            'email_length': _emailController.text.length,
            'selected_category': _selectedCategory,
            'form_valid': true,
          },
        );

        _updateStatus('Form submission tracked');

        // Clear form
        _nameController.clear();
        _emailController.clear();
        setState(() {
          _selectedCategory = _categories.first;
        });

        // Show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _updateStatus('Failed to track form submission: $e');
      }
    }
  }

  void _updateStatus(String message) {
    setState(() {
      _statusMessage = message;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Ready';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IA Tracking Examples'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.touch_app), text: 'Buttons'),
            Tab(icon: Icon(Icons.text_fields), text: 'Forms'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.navigation), text: 'Navigation'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              'Status: $_statusMessage',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildButtonsTab(),
                _buildFormsTab(),
                _buildSearchTab(),
                _buildNavigationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Button Interaction Examples',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Different button types
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Button Types',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _trackButtonTap('elevated_button', properties: {
                      'button_type': 'elevated',
                      'action': 'demo_action',
                    }),
                    child: const Text('Elevated Button'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () =>
                        _trackButtonTap('outlined_button', properties: {
                      'button_type': 'outlined',
                      'action': 'demo_action',
                    }),
                    child: const Text('Outlined Button'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        _trackButtonTap('text_button', properties: {
                      'button_type': 'text',
                      'action': 'demo_action',
                    }),
                    child: const Text('Text Button'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Icon buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Icon Buttons',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () =>
                            _trackButtonTap('favorite_button', properties: {
                          'icon': 'favorite',
                          'action': 'toggle_favorite',
                        }),
                        icon: const Icon(Icons.favorite),
                        tooltip: 'Favorite',
                      ),
                      IconButton(
                        onPressed: () =>
                            _trackButtonTap('share_button', properties: {
                          'icon': 'share',
                          'action': 'share_content',
                        }),
                        icon: const Icon(Icons.share),
                        tooltip: 'Share',
                      ),
                      IconButton(
                        onPressed: () =>
                            _trackButtonTap('download_button', properties: {
                          'icon': 'download',
                          'action': 'download_file',
                        }),
                        icon: const Icon(Icons.download),
                        tooltip: 'Download',
                      ),
                      IconButton(
                        onPressed: () =>
                            _trackButtonTap('settings_button', properties: {
                          'icon': 'settings',
                          'action': 'open_settings',
                        }),
                        icon: const Icon(Icons.settings),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Floating Action Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Floating Action Button',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Center(
                    child: FloatingActionButton(
                      onPressed: () =>
                          _trackButtonTap('fab_button', properties: {
                        'button_type': 'floating_action',
                        'action': 'create_new',
                      }),
                      tooltip: 'Create New',
                      child: const Icon(Icons.add),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Form Input Examples',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'Enter your full name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        IaTracker.instance
                            .trackTextInput(
                          'name_field',
                          'DemoScreen',
                          inputLength: value.length,
                        )
                            .catchError((e) {
                          _updateStatus('Failed to track text input: $e');
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter your email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
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
                      onChanged: (value) {
                        IaTracker.instance
                            .trackTextInput(
                          'email_field',
                          'DemoScreen',
                          inputLength: value.length,
                        )
                            .catchError((e) {
                          _updateStatus('Failed to track text input: $e');
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                          });

                          IaTracker.instance.trackCustomEvent(
                            'dropdown_selection',
                            'DemoScreen',
                            elementId: 'category_dropdown',
                            properties: {
                              'selected_value': value,
                              'previous_value': _selectedCategory,
                            },
                          ).catchError((e) {
                            _updateStatus('Failed to track dropdown: $e');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Submit Form'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Search Examples',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search Products',
              hintText: 'Type to search...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // Debounce search
              Future.delayed(const Duration(milliseconds: 500), () {
                if (_searchController.text == value) {
                  _performSearch(value);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          if (_searchResults.isNotEmpty) ...[
            Text(
              'Results (${_searchResults.length})',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: Text(item),
                    onTap: () async {
                      await IaTracker.instance.trackButtonTap(
                        'search_result_$index',
                        'DemoScreen',
                      );

                      await IaTracker.instance.trackCustomEvent(
                        'search_result_selected',
                        'DemoScreen',
                        elementId: 'search_result_$index',
                        properties: {
                          'result_position': index,
                          'result_text': item,
                          'search_query': _searchController.text,
                        },
                      );

                      _updateStatus('Selected: $item');
                    },
                  );
                },
              ),
            ),
          ] else if (_searchController.text.isNotEmpty) ...[
            const Expanded(
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'Start typing to search',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Navigation Examples',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Internal Navigation',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      IaTracker.instance
                          .trackNavigation(
                        'DemoScreen',
                        'DetailScreen',
                        method: 'push',
                      )
                          .then((_) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const DetailScreen(title: 'Product Details'),
                            settings: const RouteSettings(
                              name: 'DetailScreen',
                              arguments: {'fromScreen': 'DemoScreen'},
                            ),
                          ),
                        );
                      }).catchError((e) {
                        _updateStatus('Failed to track navigation: $e');
                      });
                    },
                    child: const Text('Go to Detail Screen'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      IaTracker.instance
                          .trackNavigation(
                        'DemoScreen',
                        'SettingsScreen',
                        method: 'push',
                      )
                          .then((_) {
                        Navigator.of(context).pushNamed('/settings');
                      }).catchError((e) {
                        _updateStatus('Failed to track navigation: $e');
                      });
                    },
                    child: const Text('Go to Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tab Navigation',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  const Text(
                      'Switch between tabs above to see tab change tracking in action.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final nextTab =
                          (_tabController.index + 1) % _tabController.length;
                      _tabController.animateTo(nextTab);
                    },
                    child: const Text('Next Tab'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Back Navigation',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      IaTracker.instance
                          .trackNavigation(
                        'DemoScreen',
                        'HomeScreen',
                        method: 'pop',
                      )
                          .then((_) {
                        Navigator.of(context).pop();
                      }).catchError((e) {
                        _updateStatus('Failed to track navigation: $e');
                      });
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple detail screen for navigation demo
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.title});
  final String title;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  @override
  void initState() {
    super.initState();
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    try {
      await IaTracker.instance.trackScreenView('DetailScreen');
    } catch (e) {
      print('Failed to track screen view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Product',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This is a detailed view of a product. User interactions here would be tracked including button taps, scrolling, and time spent on screen.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Price: \$99.99',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await IaTracker.instance
                    .trackButtonTap('add_to_cart_button', 'DetailScreen');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to cart!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Add to Cart'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                await IaTracker.instance
                    .trackButtonTap('add_to_wishlist_button', 'DetailScreen');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to wishlist!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                }
              },
              child: const Text('Add to Wishlist'),
            ),
          ],
        ),
      ),
    );
  }
}
