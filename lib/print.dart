import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide Image;
import 'package:esc_pos_bluetooth/esc_pos_bluetooth.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import 'dart:io' show Platform;
import 'package:image/image.dart';

class Print extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  Print(this.data);
  @override
  _PrintState createState() => _PrintState();
}

class _PrintState extends State<Print> {

  /*PrinterBluetoothManager _printerManager = PrinterBluetoothManager();
  List<PrinterBluetooth> _devices = [];
  String _devicesMsg;
  BluetoothManager bluetoothManager = BluetoothManager.instance;

  @override
  void initState() {
    if (Platform.isAndroid) {
      bluetoothManager.state.listen((val) {
        print('state = $val');
        if (!mounted) return;
        if (val == 12) {
          print('on');
          initPrinter();
        } else if (val == 10) {
          print('off');
          setState(() => _devicesMsg = 'Bluetooth Disconnect!');
        }
      });
    } else {
      initPrinter();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print'),
      ),
      body: _devices.isEmpty
          ? Center(child: Text(_devicesMsg ?? ''))
          : ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (c, i) {
          return ListTile(
            leading: Icon(Icons.print),
            title: Text(_devices[i].name),
            subtitle: Text(_devices[i].address),
            onTap: () {
              _startPrint(_devices[i]);
            },
          );
        },
      ),
    );
  }

  void initPrinter() {
    _printerManager.startScan(const Duration(seconds: 2));
    _printerManager.scanResults.listen((val) {
      if (!mounted) return;
      setState(() => _devices = val);
      if (_devices.isEmpty) setState(() => _devicesMsg = 'No Devices');
    });
  }

  Future<void> _startPrint(PrinterBluetooth printer) async {
    _printerManager.selectPrinter(printer);
    final result = await _printerManager.printTicket(await _ticket(PaperSize.mm80));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(result.msg),
      ),
    );
  }

  Future<Ticket> _ticket(PaperSize paper) async {
    final ticket = Ticket(paper);
    int total = 0;

    // Image assets
    final ByteData data = await rootBundle.load('assets/store.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final Image image = decodeImage(bytes);
    ticket.image(image);
    ticket.text(
      'TOKO KU',
      styles: const PosStyles(align: PosAlign.center,height: PosTextSize.size2,width: PosTextSize.size2),
      linesAfter: 1,
    );

    for (var i = 0; i < widget.data.length; i++) {
      total += widget.data[i]['total_price'];
      ticket.text(widget.data[i]['title']);
      ticket.row([
        PosColumn(
            text: '${widget.data[i]['price']} x ${widget.data[i]['qty']}',
            width: 6),
        PosColumn(text: 'Rp ${widget.data[i]['total_price']}', width: 6),
      ]);
    }

    ticket.feed(1);
    ticket.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rp $total', width: 6, styles: const PosStyles(bold: true)),
    ]);
    ticket.feed(2);
    ticket.text('Thank You',styles: const PosStyles(align: PosAlign.center, bold: true));
    ticket.cut();

    return ticket;
  }

  @override
  void dispose() {
    _printerManager.stopScan();
    super.dispose();
  }*/

  BluetoothManager bluetoothManager = BluetoothManager.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) => initBluetooth());
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initBluetooth() async {
    bluetoothManager.startScan(timeout: const Duration(seconds: 4));

    bool isConnected = await bluetoothManager.isConnected;

    bluetoothManager.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothManager.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothManager.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  void _onConnect() async {
    if (_device != null && _device!.address != null) {
      await bluetoothManager.connect(_device!);
    } else {
      setState(() {
        tips = 'please select device';
      });
      print('please select device');
    }
  }

  void _onDisconnect() async {
    await bluetoothManager.disconnect();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('widget.title'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            bluetoothManager.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(tips),
                  ),
                ],
              ),
              Divider(),
              StreamBuilder<List<BluetoothDevice>>(
                stream: bluetoothManager.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data!
                      .map((d) => ListTile(
                    title: Text(d.name ?? ''),
                    subtitle: Text(d.address ?? ""),
                    onTap: () async {
                      setState(() {
                        _device = d;
                      });
                    },
                    trailing:
                    _device != null && _device!.address == d.address
                        ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                        : null,
                  ))
                      .toList(),
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        OutlineButton(
                          child: Text('connect'),
                          onPressed: _connected ? null : _onConnect,
                        ),
                        SizedBox(width: 10.0),
                        OutlineButton(
                          child: Text('disconnect'),
                          onPressed: _connected ? _onDisconnect : null,
                        ),
                      ],
                    ),
                    OutlineButton(
                      child: Text('Send test data'),
                      onPressed: _connected ? _sendData : null,
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothManager.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => bluetoothManager.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () =>
                    bluetoothManager.startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }

  void _sendData() async {
    List<int> bytes = latin1.encode('Tui to r valo holi na\n\n\n',).toList();

    // Set codetable west. Add import 'dart:typed_data';
    // List<int> bytes = Uint8List.fromList(List.from('\x1Bt'.codeUnits)..add(6));
    // Text with special characters
    // bytes += latin1.encode('blåbærgrød\n\n\n');

    await bluetoothManager.writeData(bytes);
  }
}

