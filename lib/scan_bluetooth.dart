import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_blue_latihan/pengukuran_sensor.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/instance_manager.dart';
import 'package:get/state_manager.dart';

class ScanBluetooth extends StatefulWidget {
  const ScanBluetooth({super.key});

  @override
  State<ScanBluetooth> createState() => _ScanBluetoothState();
}

class _ScanBluetoothState extends State<ScanBluetooth> {
  final pengukuranC = Get.put(PengukuranSensor());

  List<ScanResult> scanResultList = [];
  BluetoothDevice? connectedDevice;
  BluetoothDevice? processConnectedDevice;
  BluetoothCharacteristic? receiveCharacteristic;
  BluetoothCharacteristic? sendCharacteristic;
  BluetoothCharacteristic? targetCharacteristic;

  bool _isScan = false;
  bool _loading = false;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    startScan();
  }

  Future<void> startScan() async {
    // matikan koneksi bluetooth lama
    if (connectedDevice != null) {
      AlertDialog alert = AlertDialog(
        title: const Text("Message"),
        content: Text(
            "Device ${connectedDevice?.id} still connect !, do you want to disconnect this device ?"),
        actions: [
          TextButton(
              onPressed: () async {
                Navigator.pop(context);

                await targetCharacteristic?.setNotifyValue(false);
                await connectedDevice!.disconnect();

                setState(() {
                  connectedDevice = null;
                });
              },
              child: const Text("Ok")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel")),
        ],
      );
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          });
      return;
    }

    scanResultList.clear();

    // scanning bluetooth is on or not
    StreamSubscription<BluetoothAdapterState>? subscription;
    subscription = FlutterBluePlus.adapterState
        .listen((BluetoothAdapterState state) async {
      if (state == BluetoothAdapterState.on) {
        FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 4), androidUsesFineLocation: true);

        FlutterBluePlus.isScanning.listen((isScanning) {
          setState(() {
            _isScan = isScanning;
          });
        });

        FlutterBluePlus.scanResults.listen((scanResult) {
          // final BluetoothDevice scanDevice = scanResult[0].device;
          // if (scanDevice.toString() == "FS20") {
          setState(() {
            scanResultList = scanResult;
          });
          // }
        });
      } else {
        // stop scanning
        await subscription?.cancel();
        AlertDialog alert = AlertDialog(
          title: const Text("Error !"),
          content: const Text("Bluetooth is not on !"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok")),
          ],
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            });
      }
    });
  }

  void connectToDevice(BluetoothDevice device) {
    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.on) {
        setState(() {
          _loading = true;
          processConnectedDevice = device;
        });

        device.connectionState.listen((BluetoothConnectionState state) async {
          print("state: $state");
          if (state == BluetoothConnectionState.disconnected) {
            connectedDevice = null;
          }
        });

        device.connect().then((_) {
          setState(() {
            _loading = false;
            connectedDevice = device;
            processConnectedDevice = null;
          });

          print("Connected to: $connectedDevice");
        }).onError((error, stackTrace) {
          setState(() {
            _loading = false;
            connectedDevice = null;
            processConnectedDevice = null;
          });

          final AlertDialog alert;
          if (error is FlutterBluePlusException) {
            alert = AlertDialog(
              title: Text("${error.code} !"),
              content: Text(error.description.toString()),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Ok")),
              ],
            );
          } else {
            alert = AlertDialog(
              title: const Text("Error !"),
              content: Text(error.toString()),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Ok")),
              ],
            );
          }
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return alert;
              });
          print("Error: $error");
        });
      } else {
        AlertDialog alert = AlertDialog(
          title: const Text("Error !"),
          content: const Text("Bluetooth is not on !"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok")),
          ],
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            });
      }
    });
  }

  showAlertDialog(BuildContext context) {
    // Size size = MediaQuery.of(context).size;
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () async {
        Navigator.pop(context);
        await targetCharacteristic?.setNotifyValue(false);
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Hasil Pengukuran Sensor"),
      content: SizedBox(
        height: 200,
        child: Obx(
          () => Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Oksigen Darah",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 0.0), //(x,y)
                            blurRadius: 2.0,
                            spreadRadius: 0.0,
                          )
                        ],
                      ),
                      child: Center(
                          child: Text("${pengukuranC.oksigenDarah.value} %")),
                    )
                  ],
                ),
              ),
              const SizedBox(
                width: 10.0,
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text(
                      "Detak Jantung",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.grey,
                            offset: Offset(0.0, 0.0), //(x,y)
                            blurRadius: 2.0,
                            spreadRadius: 0.0,
                          )
                        ],
                      ),
                      child: Center(
                          child: Column(
                        children: [
                          Text("${pengukuranC.detakJantung.value}"),
                          const Text("detak/menit")
                        ],
                      )),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        okButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> readSensorData(BuildContext context) async {
    try {
      final bluetoothState = FlutterBluePlus.adapterState;
      if (bluetoothState == BluetoothAdapterState.off) {
        AlertDialog alert = AlertDialog(
          title: const Text("Error !"),
          content: const Text("Bluetooth is not on !"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok")),
          ],
        );
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            });
      } else {
        showAlertDialog(context);

        List<BluetoothService> services =
            await connectedDevice!.discoverServices();

        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString() ==
                "0000ffe4-0000-1000-8000-00805f9b34fb") {
              targetCharacteristic = characteristic;
              break;
            }
          }
        }

        StreamSubscription<List<int>>? subscription;
        subscription =
            targetCharacteristic?.onValueReceived.listen((List<int> value) {
          if (value.length == 10) {
            pengukuranC.detakJantung.value = value[4].toDouble();
            pengukuranC.oksigenDarah.value = value[5].toDouble();
          }
        });

        await targetCharacteristic?.setNotifyValue(true);

        // // berhenti ketika 10 detik scan
        // Timer(const Duration(seconds: 15), () async {
        //   // Stop receiving notifications
        //   await targetCharacteristic?.setNotifyValue(false);
        //   // Stop notifications
        //   await subscription?.cancel();
        //   print('Notifications stopped after 10 seconds');
        // });

        // listen for disconnection
        // matikan saja scaffoldnya, bikin resah
        connectedDevice!.connectionState
            .listen((BluetoothConnectionState state) {
          if (state == BluetoothConnectionState.disconnected) {
            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //     content: Text("Device ${connectedDevice?.id} disconnected !")));
            // stop listening to characteristic
            subscription?.cancel();
          }
        });
      }
    } catch (e) {
      print("Error saat membaca data sensor: $e");

      connectedDevice!.disconnect();

      setState(() {
        connectedDevice = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterBlue Communication'),
      ),
      body: Builder(builder: (BuildContext context) {
        if (scanResultList.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20.0, top: 20.0),
            itemCount: scanResultList.length,
            itemBuilder: (context, index) {
              var deviceName = scanResultList[index].device.name == ""
                  ? "Unknown Device"
                  : scanResultList[index].device.name.toString();

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: ListTile(
                  title: Text(scanResultList[index].device.id.toString()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Status Connectable: ${scanResultList[index].advertisementData.connectable.toString()}"),
                      Text("Device Name : $deviceName"),
                    ],
                  ),
                  onTap: () {},
                  trailing: Builder(builder: (BuildContext context) {
                    // Loading connect
                    if (_loading == true &&
                        processConnectedDevice!.id ==
                            scanResultList[index].device.id) {
                      return IconButton(
                          onPressed: () {},
                          icon: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator()));
                    }

                    // jika belum ada device yang connect
                    if (connectedDevice == null) {
                      return IgnorePointer(
                        ignoring: _loading,
                        child: IconButton(
                            icon: const Icon(Icons.bluetooth),
                            onPressed: () async {
                              connectToDevice(scanResultList[index].device);
                            }),
                      );
                    }

                    /// jika ada proses koneksi
                    // dan jika perangkat sedang dikoneksikan
                    if (connectedDevice!.id ==
                        scanResultList[index].device.id) {
                      return SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.bluetooth_disabled),
                                onPressed: () async {
                                  try {
                                    final BluetoothDevice device =
                                        scanResultList[index].device;

                                    await targetCharacteristic
                                        ?.setNotifyValue(false);
                                    await device.disconnect();

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          "Succesfully disconnected from ${device.id}"),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    // print("Successfully disconnected ${device.id}");

                                    setState(() {
                                      connectedDevice = null;
                                    });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(e.toString()),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                    // print("Error disconnecting : $e");
                                  }
                                }),
                            IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () async {
                                  await readSensorData(context);
                                })
                          ],
                        ),
                      );
                    }

                    return const Text("");
                  }),
                ),
              );
            },
          );
        } else {
          return Container(
            child: const Center(child: Text("Data Kosong...")),
          );
        }
      }),
      floatingActionButton: Container(
        child: _isScan != true
            ? FloatingActionButton(
                onPressed: () {
                  startScan();
                },
                child: const Icon(Icons.search),
              )
            : FloatingActionButton(
                onPressed: () {},
                child: const Icon(Icons.rectangle),
              ),
      ),
    );
  }
}
