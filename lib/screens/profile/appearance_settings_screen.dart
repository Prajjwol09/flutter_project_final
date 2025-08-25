import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finlytic/utils/design_tokens.dart';
import 'package:finlytic/widgets/cards.dart';
import 'package:finlytic/providers/theme_provider.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends ConsumerState<AppearanceSettingsScreen> {
  String _selectedTheme = 'System';
  String _selectedAccentColor = 'Blue';
  bool _useSystemFonts = false;
  String _selectedFontSize = 'Medium';
  bool _reducedMotion = false;
  bool _highContrast = false;

  final List<Map<String, dynamic>> _themes = [
    {'name': 'Light', 'icon': Icons.light_mode, 'value': ThemeMode.light},
    {'name': 'Dark', 'icon': Icons.dark_mode, 'value': ThemeMode.dark},
    {'name': 'System', 'icon': Icons.brightness_auto, 'value': ThemeMode.system},
  ];

  final List<Map<String, dynamic>> _accentColors = [
    {'name': 'Blue', 'color': Colors.blue, 'value': 'blue'},
    {'name': 'Green', 'color': Colors.green, 'value': 'green'},
    {'name': 'Purple', 'color': Colors.purple, 'value': 'purple'},
    {'name': 'Orange', 'color': Colors.orange, 'value': 'orange'},
    {'name': 'Red', 'color': Colors.red, 'value': 'red'},
    {'name': 'Teal', 'color': Colors.teal, 'value': 'teal'},
  ];

  final List<String> _fontSizes = ['Small', 'Medium', 'Large', 'Extra Large'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Appearance'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Section
            _buildSectionTitle('Theme'),
            _buildThemeSelection(),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Color Section
            _buildSectionTitle('Accent Color'),
            _buildAccentColorSelection(),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Typography Section
            _buildSectionTitle('Typography'),
            _buildTypographySettings(),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Accessibility Section
            _buildSectionTitle('Accessibility'),
            _buildAccessibilitySettings(),
            
            const SizedBox(height: DesignTokens.space6),
            
            // Preview Section
            _buildSectionTitle('Preview'),
            _buildPreviewCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildThemeSelection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Theme',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Select your preferred theme mode',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Row(
            children: _themes.map((themeOption) {
              final isSelected = themeOption['name'] == _selectedTheme;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTheme = themeOption['name']);
                      ref.read(themeModeProvider.notifier).setThemeMode(themeOption['value']);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.space3),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        border: Border.all(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            themeOption['icon'],
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          const SizedBox(height: DesignTokens.space1),
                          Text(
                            themeOption['name'],
                            style: TextStyle(
                              color: isSelected 
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccentColorSelection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Choose your preferred accent color',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Wrap(
            spacing: DesignTokens.space3,
            runSpacing: DesignTokens.space3,
            children: _accentColors.map((colorOption) {
              final isSelected = colorOption['name'] == _selectedAccentColor;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedAccentColor = colorOption['name']);
                  // In a real app, you would update the theme's accent color
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colorOption['color'],
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: isSelected 
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: isSelected 
                        ? [BoxShadow(
                            color: colorOption['color'].withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )]
                        : null,
                  ),
                  child: isSelected 
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTypographySettings() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use System Fonts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Use your device\'s default font',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useSystemFonts,
                onChanged: (value) => setState(() => _useSystemFonts = value),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space4),
          const Divider(),
          const SizedBox(height: DesignTokens.space4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Font Size',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Adjust text size for better readability',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              Wrap(
                spacing: DesignTokens.space2,
                children: _fontSizes.map((size) {
                  final isSelected = size == _selectedFontSize;
                  return ChoiceChip(
                    label: Text(size),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFontSize = size);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessibilitySettings() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reduced Motion',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Minimize animations and transitions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _reducedMotion,
                onChanged: (value) => setState(() => _reducedMotion = value),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          const Divider(),
          const SizedBox(height: DesignTokens.space2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'High Contrast',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Increase contrast for better visibility',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _highContrast,
                onChanged: (value) => setState(() => _highContrast = value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _accentColors.firstWhere((c) => c['name'] == _selectedAccentColor)['color'],
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Transaction',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Food & Dining',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$25.50',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _accentColors.firstWhere((c) => c['name'] == _selectedAccentColor)['color'],
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  '60% of budget used',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}