import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rhythm_box/services/audio_player/audio_player.dart';

class PlayerDevicePopup extends StatefulWidget {
  const PlayerDevicePopup({super.key});

  @override
  State<PlayerDevicePopup> createState() => _PlayerDevicePopupState();
}

class _PlayerDevicePopupState extends State<PlayerDevicePopup> {
  late Future<List<AudioDevice>> devicesFuture;
  late Stream<List<AudioDevice>> devicesStream;
  late Future<AudioDevice> selectedDeviceFuture;
  late Stream<AudioDevice> selectedDeviceStream;

  @override
  void initState() {
    super.initState();
    devicesFuture = audioPlayer.devices;
    devicesStream = audioPlayer.devicesStream;
    selectedDeviceFuture = audioPlayer.selectedDevice;
    selectedDeviceStream = audioPlayer.selectedDeviceStream;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Devices',
          style: Theme.of(context).textTheme.headlineSmall,
        ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
        Expanded(
          child: StreamBuilder<List<AudioDevice>>(
            stream: devicesStream,
            builder: (context, devicesSnapshot) {
              return FutureBuilder<List<AudioDevice>>(
                future: devicesFuture,
                builder: (context, devicesFutureSnapshot) {
                  final devices =
                      devicesSnapshot.data ?? devicesFutureSnapshot.data;

                  return StreamBuilder<AudioDevice>(
                    stream: selectedDeviceStream,
                    builder: (context, selectedDeviceSnapshot) {
                      return FutureBuilder<AudioDevice>(
                        future: selectedDeviceFuture,
                        builder: (context, selectedDeviceFutureSnapshot) {
                          final selectedDevice = selectedDeviceSnapshot.data ??
                              selectedDeviceFutureSnapshot.data;

                          if (devices == null || selectedDevice == null) {
                            return const CircularProgressIndicator();
                          }

                          return ListView.builder(
                            itemCount: devices.length,
                            itemBuilder: (context, idx) {
                              final device = devices[idx];
                              return ListTile(
                                leading: const Icon(Icons.speaker),
                                title: Text(device.description),
                                subtitle: Text(device.name),
                                selected: selectedDevice == device,
                                onTap: () => audioPlayer.setAudioDevice(device),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
