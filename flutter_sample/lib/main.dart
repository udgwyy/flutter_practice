import 'package:flutter/material.dart';
import 'package:flutter_sample/google_http_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart';

void main() => runApp(MyApp());

GoogleSignInAccount _currentUser;

GoogleSignIn _googleSignIn = new GoogleSignIn(
  scopes: <String>[
    SheetsApi.SpreadsheetsScope,
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have clicked the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.list),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


  void _incrementCounter() {
    _counter++;
    _handleSignIn().then((onValue){
      _account();
      _counter++;
    }).catchError((error){
      print(error);
    });
  }

  Future<Null> _handleSignIn() async {
    _googleSignIn.signIn();
  }

  _account() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount user) {
      _currentUser = user;
      _create();
    });
    _googleSignIn.signInSilently();
  }

  _create() {
    _currentUser.authHeaders.then((authHeaders){
      final SheetsApi api = SheetsApi(GoogleHttpClient(authHeaders));
      var request = Spreadsheet();
      api.spreadsheets.create(request).then((Spreadsheet response){
        print("=============== created spreadsheetId : " + response.spreadsheetId);
        print("=============== created spreadsheetUrl : " + response.spreadsheetUrl);
        _title(api, response.spreadsheetId);
      }).whenComplete((){
        print("=============== complet Created");
      }).catchError((onError){
        print("=============== catch Error");
      });


    });
  }

  _title(SheetsApi api, String spreadsheetId){

    // update spreadsheet title
    Request spreadsheetUpdateRequest = Request();
    var updateSpreadsheetPropertiesRequest = UpdateSpreadsheetPropertiesRequest();
    updateSpreadsheetPropertiesRequest.fields = "title";
    updateSpreadsheetPropertiesRequest.properties = SpreadsheetProperties();
    updateSpreadsheetPropertiesRequest.properties.title = "生活リズムケア";
    spreadsheetUpdateRequest.updateSpreadsheetProperties = updateSpreadsheetPropertiesRequest;

    // delete sheet
    Request sheetDeleteRequest = Request();
    var deleteSheetRequest = DeleteSheetRequest();
    deleteSheetRequest.sheetId = 0; // 初期作成シート
    sheetDeleteRequest.deleteSheet = deleteSheetRequest;

    // add sheet & title
    Request sheetAddRequest = Request();
    var addSheetRequest = AddSheetRequest();
    addSheetRequest.properties = SheetProperties();
    addSheetRequest.properties.title = "睡眠";
    sheetAddRequest.addSheet = addSheetRequest;

    // call Update
    BatchUpdateSpreadsheetRequest batchUpdateSpreadsheetRequest = BatchUpdateSpreadsheetRequest();
    List<Request> requestList = List();
    requestList.add(spreadsheetUpdateRequest);
    requestList.add(sheetAddRequest);
    requestList.add(sheetDeleteRequest);
    batchUpdateSpreadsheetRequest.requests = requestList;
    api.spreadsheets.batchUpdate(batchUpdateSpreadsheetRequest, spreadsheetId).then((BatchUpdateSpreadsheetResponse response){
      response.replies.forEach((replied){
        if(replied  != null && replied.addSheet != null && replied.addSheet.properties != null){
          _write(api, spreadsheetId, replied.addSheet.properties.sheetId);
        }
      });
    }).whenComplete((){
      print("=============== title complet");
    });

    // TODO:read Content

  }

  _write (SheetsApi api, String spreadsheetId, int sheetId){

    var updateCellsRequest = UpdateCellsRequest();
    updateCellsRequest.fields = "*";

    var row = RowData();
    row.values = List<CellData>();
    var cellData = CellData();
    cellData.note = "note_sample";
    row.values.add(cellData);
    List<RowData> rowDataList = List<RowData>();
    rowDataList.add(row);
    updateCellsRequest.rows = rowDataList;

    var gridRange = GridRange();
    gridRange.sheetId = sheetId;
    gridRange.startColumnIndex = 1;
    gridRange.startRowIndex = 1;
    updateCellsRequest.range = gridRange;

    Request contentUpdateRequest = Request();
    contentUpdateRequest.updateCells = updateCellsRequest;
    List<Request> requestList = List();
    requestList.add(contentUpdateRequest);
    BatchUpdateSpreadsheetRequest batchUpdateSpreadsheetRequest = BatchUpdateSpreadsheetRequest();
    batchUpdateSpreadsheetRequest.requests = requestList;
    api.spreadsheets.batchUpdate(batchUpdateSpreadsheetRequest, spreadsheetId).then((BatchUpdateSpreadsheetResponse response){
      response.replies.forEach((replied){
        if(replied  != null && replied.addSheet != null && replied.addSheet.properties != null){
          print("=============== write response : " + replied.toString() );
        }
      });
    }).whenComplete((){
      print("=============== write complet");
    });
  }

  _read(SheetsApi api, String spreadsheetId, int sheetId){

  }

}
