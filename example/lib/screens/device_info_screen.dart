import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ia_tracking/ia_tracking.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
    // Track screen view when entering device info screen
    IaTracker.instance.trackScreenView('Device Info Screen');
  }

  Future<void> _loadDeviceInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceData = await _getDeviceInfo();
      setState(() {
        _deviceData = deviceData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get device info: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final deviceData = <String, dynamic>{};

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      deviceData.addAll(_getAndroidInfo(androidInfo));
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfoPlugin.iosInfo;
      deviceData.addAll(_getIOSInfo(iosInfo));
    } else if (kIsWeb) {
      final webInfo = await _deviceInfoPlugin.webBrowserInfo;
      deviceData.addAll(_getWebInfo(webInfo));
    } else if (Platform.isMacOS) {
      final macInfo = await _deviceInfoPlugin.macOsInfo;
      deviceData.addAll(_getMacOSInfo(macInfo));
    } else if (Platform.isWindows) {
      final windowsInfo = await _deviceInfoPlugin.windowsInfo;
      deviceData.addAll(_getWindowsInfo(windowsInfo));
    } else if (Platform.isLinux) {
      final linuxInfo = await _deviceInfoPlugin.linuxInfo;
      deviceData.addAll(_getLinuxInfo(linuxInfo));
    }

    // Add common information
    deviceData['platform'] = _getPlatformName();
    deviceData['collected_at'] = DateTime.now().toIso8601String();

    return deviceData;
  }

  Map<String, dynamic> _getAndroidInfo(AndroidDeviceInfo info) {
    return {
      'Platform': 'Android',
      'Device Model': info.model,
      'Device Brand': info.brand,
      'Manufacturer': info.manufacturer,
      'Product': info.product,
      'Hardware': info.hardware,
      'Board': info.board,
      'Bootloader': info.bootloader,
      'Android Version': info.version.release,
      'SDK Version': info.version.sdkInt.toString(),
      'Security Patch': info.version.securityPatch ?? 'Unknown',
      'Incremental': info.version.incremental,
      'Codename': info.version.codename,
      'Base OS': info.version.baseOS ?? 'Unknown',
      'Supported ABIs': info.supportedAbis.join(', '),
      'Supported 32-bit ABIs': info.supported32BitAbis.join(', '),
      'Supported 64-bit ABIs': info.supported64BitAbis.join(', '),
      'Is Physical Device': info.isPhysicalDevice ? 'Yes' : 'No',
      'System Features': info.systemFeatures.take(5).join(', ') +
          (info.systemFeatures.length > 5 ? '...' : ''),
    };
  }

  Map<String, dynamic> _getIOSInfo(IosDeviceInfo info) {
    return {
      'Platform': 'iOS',
      'Device Name': info.name,
      'Model': info.model,
      'Localized Model': info.localizedModel,
      'System Name': info.systemName,
      'System Version': info.systemVersion,
      'Identifier for Vendor': info.identifierForVendor ?? 'Unknown',
      'Is Physical Device': info.isPhysicalDevice ? 'Yes' : 'No',
      'System Name (utsname)': info.utsname.sysname,
      'Node Name': info.utsname.nodename,
      'Release': info.utsname.release,
      'Version': info.utsname.version,
      'Machine': info.utsname.machine,
    };
  }

  Map<String, dynamic> _getWebInfo(WebBrowserInfo info) {
    return {
      'Platform': 'Web',
      'Browser Name': info.browserName.name,
      'App Code Name': info.appCodeName ?? 'Unknown',
      'App Name': info.appName ?? 'Unknown',
      'App Version': info.appVersion ?? 'Unknown',
      'Device Memory': info.deviceMemory?.toString() ?? 'Unknown',
      'Language': info.language ?? 'Unknown',
      'Languages': info.languages?.join(', ') ?? 'Unknown',
      'Platform Type': info.platform ?? 'Unknown',
      'Product': info.product ?? 'Unknown',
      'User Agent': info.userAgent ?? 'Unknown',
      'Vendor': info.vendor ?? 'Unknown',
      'Hardware Concurrency': info.hardwareConcurrency?.toString() ?? 'Unknown',
      'Max Touch Points': info.maxTouchPoints?.toString() ?? 'Unknown',
    };
  }

  Map<String, dynamic> _getMacOSInfo(MacOsDeviceInfo info) {
    return {
      'Platform': 'macOS',
      'Computer Name': info.computerName,
      'Host Name': info.hostName,
      'Architecture': info.arch,
      'Model': info.model,
      'Kernel Version': info.kernelVersion,
      'OS Version':
          '${info.majorVersion}.${info.minorVersion}.${info.patchVersion}',
      'OS Release': info.osRelease,
      'Active CPUs': info.activeCPUs.toString(),
      'Memory Size':
          '${(info.memorySize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB',
      'CPU Frequency': '${info.cpuFrequency} MHz',
      'System GUID': info.systemGUID ?? 'Unknown',
    };
  }

  Map<String, dynamic> _getWindowsInfo(WindowsDeviceInfo info) {
    return {
      'Platform': 'Windows',
      'Computer Name': info.computerName,
      'Number of Cores': info.numberOfCores.toString(),
      'System Memory': '${info.systemMemoryInMegabytes} MB',
      'User Name': info.userName,
      'OS Version':
          '${info.majorVersion}.${info.minorVersion}.${info.buildNumber}',
      'Platform ID': info.platformId.toString(),
      'CSD Version': info.csdVersion,
      'Service Pack': '${info.servicePackMajor}.${info.servicePackMinor}',
      'Product Type': info.productType.toString(),
      'Product Name': info.productName,
      'Edition ID': info.editionId,
      'Release ID': info.releaseId,
      'Device ID': info.deviceId,
    };
  }

  Map<String, dynamic> _getLinuxInfo(LinuxDeviceInfo info) {
    return {
      'Platform': 'Linux',
      'Name': info.name,
      'Version': info.version ?? 'Unknown',
      'ID': info.id,
      'ID Like': info.idLike?.join(', ') ?? 'Unknown',
      'Version Codename': info.versionCodename ?? 'Unknown',
      'Version ID': info.versionId ?? 'Unknown',
      'Pretty Name': info.prettyName,
      'Build ID': info.buildId ?? 'Unknown',
      'Variant': info.variant ?? 'Unknown',
      'Variant ID': info.variantId ?? 'Unknown',
      'Machine ID': info.machineId ?? 'Unknown',
    };
  }

  String _getPlatformName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isFuchsia) return 'Fuchsia';
    if (kIsWeb) return 'Web';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Information'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadDeviceInfo,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Device Info',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading device information...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDeviceInfo,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header with action buttons
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Comprehensive device details for tracking integration',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _trackWithDeviceInfo,
                    icon: const Icon(Icons.track_changes),
                    label: const Text('Track with Device Info'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _copyToClipboard,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy JSON'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Device info list
        Expanded(
          child: ListView.builder(
            itemCount: _deviceData.length,
            itemBuilder: (context, index) {
              final entry = _deviceData.entries.elementAt(index);
              return _buildInfoTile(entry.key, entry.value.toString());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () => _copyValue(value),
        tooltip: 'Copy value',
      ),
      dense: true,
    );
  }

  Future<void> _trackWithDeviceInfo() async {
    try {
      // Example: Track custom event with device info as properties
      await IaTracker.instance.trackCustomEvent(
        'device_info_viewed',
        'Device Info Screen',
        properties: _deviceData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device info tracked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to track device info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    // In a real app, you would copy to clipboard
    // For now, just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device info JSON would be copied to clipboard'),
        ),
      );
    }
  }

  Future<void> _copyValue(String value) async {
    // In a real app, you would copy to clipboard
    // For now, just show a message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Copied: ${value.length > 50 ? '${value.substring(0, 50)}...' : value}'),
        ),
      );
    }
  }
}
