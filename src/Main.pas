unit Main;

interface

uses
	Windows, Messages, SysUtils, Graphics, Forms, ShellAPI,
	Controls, Classes, ExtCtrls, StdCtrls, lcdg15, Menus;

const
	//Tray icon
	WM_ICONTRAY  = WM_USER+1;

type
	TForm1 = class(TForm)
		Label1: TLabel;
		Image1: TImage;
		MCTTimer: TTimer;
		PopupMenu1: TPopupMenu;
		Exit1: TMenuItem;
		Button1: TButton;
		Button2: TButton;
		Button3: TButton;
		Button4: TButton;
    StatTimer: TTimer;
		procedure Button1Click(Sender: TObject);
		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure Exit1Click(Sender: TObject);
		procedure FormClose(Sender: TObject; var Action: TCloseAction);
		procedure MCTTimerExecute(Sender: TObject);
		procedure Button4Click(Sender: TObject);
		procedure Button2Click(Sender: TObject);
		procedure Button3Click(Sender: TObject);
    procedure StatTimerTimer(Sender: TObject);
	private
		{ Private declarations }
		TrayIconData: TNotifyIconData; //Tray Icon
	public
		{ Public declarations }
		procedure TrayMessage(var Msg: TMessage); message WM_ICONTRAY; //Tray Icon
		procedure LCDError(ID : Byte);
		procedure LCDPress(ID : integer);
	end;



var
	Form1: TForm1;

implementation
uses
	Types,
	Dates,
	DateUtils;

{$R *.dfm}

var
	MxOHandle : THandle;
	ARect : TRect;
	HPBitmap : TBitmap;
	ISBitmap : TBitmap;
	LCD : TLcdG15;
	LinkArray : array [1..4] of string;
	AppPath : string;

//Forward the Execution Method
procedure ExecuteMCT; forward;
procedure ExecuteStat; forward;

procedure ClearCanvas; forward;//Clear the canvas
procedure WriteHeader; forward;//Write "The Matrix Online" on the screen

//Forward the Screenshot method
procedure ScreenShot(x : integer; y : integer; Width : integer; Height : integer; bm : TBitMap); forward;

//Forward the LoadLinks method
procedure LoadLinks; forward;

{                         }
{ FORM RELATED PROCEDURES }
{                         }

//Execute it on the timer
procedure TForm1.MCTTimerExecute(Sender: TObject);
begin
	ExecuteMCT;
end;

procedure TForm1.StatTimerTimer(Sender: TObject);
begin
	ExecuteStat;
end;

procedure TForm1.LCDError(ID : Byte);
begin
	//ShowMessage(IntToStr(ID));
end;

procedure TForm1.LCDPress(ID : integer);
begin
	if (FindWindow(nil,'The Matrix Online') = 0) then
	begin
		case ID of
		1:  if LinkArray[1] <> '' then ShellExecute(Form1.Handle, nil,PChar(AppPath+LinkArray[1]), nil, nil, SW_SHOW);
		2:  if LinkArray[2] <> '' then ShellExecute(Form1.Handle, nil,PChar(AppPath+LinkArray[2]), nil, nil, SW_SHOW);
		4:  if LinkArray[3] <> '' then ShellExecute(Form1.Handle, nil,PChar(AppPath+LinkArray[3]), nil, nil, SW_SHOW);
		8:  if LinkArray[4] <> '' then ShellExecute(Form1.Handle, nil,PChar(AppPath+LinkArray[4]), nil, nil, SW_SHOW);
		end;
	end;
end;

//Handles what you do with the tray icon
procedure TForm1.TrayMessage(var Msg: TMessage);
var
	p : TPoint;
begin
	case Msg.lParam of
		WM_LBUTTONDOWN:
		begin
			if Form1.Showing then Form1.Hide else Form1.Show;
		end;
		WM_RBUTTONDOWN:
		begin
			SetForegroundWindow(Handle);
			GetCursorPos(p);
			PopUpMenu1.Popup(p.x, p.y);
			PostMessage(Handle, WM_NULL, 0, 0);
		end;
	end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
	LCDPress(1);
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
	LCDPress(2);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
	LCDPress(4);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
	LCDPress(8);
end;

//Handles the tray menu closing of the application, the only way to kill it.
procedure TForm1.Exit1Click(Sender: TObject);
begin
	Halt;
end;

//Don't kill the app, just hide it.  Close via system tray
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
	Action := caNone;
	Hide;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
	//Init the bitmaps
	HPBitmap := TBitmap.Create;
	ISBitmap := TBitmap.Create;
	//Set the writing part for the canvas
	image1.Canvas.Brush.Color := clwhite;
	image1.Canvas.Font.Color := clblack;
	image1.Canvas.Font.Name := 'Terminal';
	image1.Canvas.Font.Size := 8;

	ClearCanvas; //Clear the canvas
	WriteHeader; //Write "The Matrix Online" on the screen

	//Get Current Path
	AppPath		:= ExtractFilePath(ParamStr(0));

	//Setup Link files
	LoadLinks;

	//Get Current Directory

	with TrayIconData do
	begin
		cbSize := SizeOf(TrayIconData);
		Wnd := Handle;
		uID := 0;
		uFlags := NIF_MESSAGE + NIF_ICON + NIF_TIP;
		uCallbackMessage := WM_ICONTRAY;
		hIcon := Application.Icon.Handle;
		StrPCopy(szTip, Application.Title);
	end;

	Shell_NotifyIcon(NIM_ADD, @TrayIconData);

	//Init LCD.  If it fails, it'll Assert error, and bail. >_>
	//Got to recode this lame piece of BS
	//Maybe, just maybe, it'll be a better plugin module than it is now.
	LCD := TLcdG15.Create;
	LCD.OnSoftButtons := Form1.LCDPress;
	LCD.LCDCanvas := Image1.Canvas;
	LCD.OnConfigure := Form1.Show;
	LCD.OnError := Form1.LCDError;
	LCD.Connect('The Matrix Online',false,false,false);
	MCTTimer.Enabled := true;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
	//FREE THE BITMAPS!!!!!!
	HPBitmap.Free;
	ISBitmap.Free;
	//FREE & TERMINATE THE LCD
	LCD.Free;
	//Remove Icon
	//Shell_NotifyIcon(NIM_DELETE, @TrayIconData)
end;

{                               }
{  MAIN APPLICATION FUNCTIONS   }
{                               }

//Get the shortcut files
procedure LoadLinks;
var
	searchResult : TSearchRec;
	idx : word;
begin
	idx := 1;
	//look for any link files
	if FindFirst('*.lnk', faAnyFile, searchResult) = 0 then
	begin
		repeat
			LinkArray[idx] := searchResult.name;
			Inc(idx);
		until (FindNext(searchResult) <> 0) or (idx > 4);
		// Must free up resources used by these successful finds
		FindClose(searchResult);
	end;
end;


//This preps the bitmaps for display, as its either something or just white.
procedure FixBitmapBars(var Bar : TBitmap);
var
	idx : integer;
	Color: Longint;
	r, g, b: Byte;
begin
	//Set the extra pixel that is captured to a black, but tweaked where it won't
	//be turned white.
	//The Array is 0 based, so 124 = pixel # 125
	//2 colors only
	//Set the last pixel to be the 100% marker
	Bar.Canvas.Pixels[124,0] := RGB($20,$21,$20);
	//Go through all the pixels.  The space not claimed by health
	//has the same number across R G and B
	for idx := 0 to 124 do
	begin
		Color := ColorToRGB(Bar.Canvas.Pixels[idx,0]);
		r     := Color;
		g     := Color shr 8;
		b     := Color shr 16;
		if (r=g) and (r=b) and (g=b) then
		begin
			//OMG its the same! Change to white!
			Bar.Canvas.Pixels[idx,0] := clWhite;
		end;
	end;
end;

//Read the Player HP via pixel reading
procedure ReadPlayerHP;
var
	MyPt : TPoint;
begin
	//Set the top X coordinate.
	MyPt.X := ARect.Right - 177; //177 Paces from the right.
	MyPt.Y := 23; // 23 Paces down, 0 based pixel as well.
	//Convert this point to the overall screen window.
	Windows.ClientToScreen(MxOHandle,MyPt);
	//Copy the pixels. Its 124px wide, and copy the last for a stop point, and 1 down
	Screenshot(MyPt.X,MyPt.Y,125,1,HPBitmap);
	//HPBitmap.SaveToFile('c:\testPHPout.bmp'); DEBUG
	FixBitmapBars(HPBitmap); //Fix the HP pixels
	Form1.Image1.Canvas.TextOut(0,20,'HP'); //Write HP on the screen
	Form1.Image1.Canvas.StretchDraw( //Paste the pixels and stretch for visibility
		Rect(15,20,140,27),
		HPBitmap
	);
end;

//Read the Player IS
procedure ReadPlayerIS;
var
	MyPt : TPoint;
begin
	//Set the top X coordinate.
	MyPt.X := ARect.Right - 177;// 1280 - 177 should come out to 1103;
	MyPt.Y := 33; //177 Paces from the right.
	//Convert this point to the overall screen window
	Windows.ClientToScreen(MxOHandle,MyPt);
	//Copt the pixels.  Its 124px wide, and copy the last for a stop point, and 1 down
	Screenshot(MyPt.X,MyPt.Y,125,1,ISBitmap);
	//ISBitmap.SaveToFile('c:\testPISout.bmp'); DEBUG
	FixBitmapBars(ISBitmap); //Fix the IS pixels
	Form1.Image1.Canvas.TextOut(0,28,'IS'); //Write IS on the screen
	Form1.Image1.Canvas.StretchDraw( //Paste the pixels and stretch for visibility
		Rect(15,28,140,35),
		ISBitmap
	);
end;

procedure WriteHeader;
begin
	//Write the header
	Form1.Image1.Canvas.TextOut(28,1,'The Matrix Online');
end;

//Write the Matrix City Time
procedure WriteMCT;
var
	MyTime : TDateTime;
begin
	//Clear part for the time
	Form1.Image1.Canvas.FillRect(Rect(0,12,160,20));
	//Get the time
	MyTime := Now;
	//Convert to UTC
	MyTime := LocalToUTC(MyTime);
	//Take off 8 hrs for Pacific
	MyTime := IncHour(MyTime,-8);
	Form1.Image1.Canvas.TextOut(0,12,'MCT Time: ' +
		ShortDayNames[DayOfTheWeek(MyTime)] + ' ' +
		TimeToStr(MyTime)
	);
end;

procedure ClearCanvas;
begin
	//Clear via FillRect, so we don't have a border.
	Form1.Image1.Canvas.FillRect(Form1.Image1.ClientRect);
end;

//Draw a pointy arrow along the bottom
// .....
//  ...
//   .
//Just specify how from the left for the top left most pixel
procedure DrawDownArrow(SpaceFromLeft : integer);
var
	idx : integer;
begin
	with Form1.Image1.Canvas do
	begin
		for idx := 0 to 4 do Pixels[SpaceFromLeft+idx,40] := clBlack;
		for idx := 0 to 2 do Pixels[SpaceFromLeft+1+idx,41] := clBlack;
		Pixels[SpaceFromLeft+2,42] := clBlack;
	end;
end;

procedure DrawLinks;
var
	idx : word;
	ArrowPos : word;
	WordPos : TPoint;
	function Strip(Input:String) : string;
	begin
		Input := StringReplace(Input,' ','',[]);
		Input := StringReplace(Input,'.lnk','',[]);
		if Length(Input) > 6 then Input := Copy(Input,0,6);
		Result := Input;
	end;

begin
	(*

	Layout ?
		5		6		7
	1		2		3		4
	---------------------------------------------------
	*		*		*		*

	*)
	ArrowPos := 0;
	WordPos := Point(0,0);
	for idx := 1 to 4 do
	begin
		//if LinkArray[idx] = '' then break;
		begin
			case idx of
			1: begin ArrowPos := 15; WordPos := Point(0,32); end;
			2: begin ArrowPos := 55; WordPos := Point(40,32); end;//Draw name at this position
			3: begin ArrowPos := 95; WordPos := Point(80,32); end;//Draw name at this position
			4: begin ArrowPos := 140; WordPos := Point(125,32); end;//Draw name at this position
			end;
		end;
		Form1.Image1.Canvas.TextOut(WordPos.X,WordPos.Y,Strip(LinkArray[idx]));
		DrawDownArrow(ArrowPos);
	end;
end;

//The main procedure
//Calls all the rest really
procedure ExecuteMCT;
begin
	WriteHeader; //Write "The Matrix Online" on the screen
	WriteMCT; //Write the MCT Time
	LCD.SendToDisplay;
end;

procedure ExecuteStat;
begin
	//Clear writing area
	Form1.Image1.Canvas.FillRect(Rect(0,20,160,43));
	//Check
	MxOHandle := FindWindow(nil,'The Matrix Online'); //Attempt to find the game
	//Sleep(6000); //Debug!!!!!!
	if MxOHandle = 0 then //If no client is found
	begin //Present the Jack In and Draw the down arrow
		DrawLinks;
	end else
	begin
		//If its the top most window
		if MxOHandle = GetForegroundWindow() then
		begin
			//Get and store the MxO Screen size
			Windows.GetClientRect(MxOHandle,ARect);
			ReadPlayerHP;  //Read HP
			ReadPlayerIS;  //Read SP
		end
		else
		begin
			//It wson't on top, so write Vitals Unavailable
			Form1.Image1.Canvas.TextOut(0,28,'Vitals Unavailable');
		end;
	end;
	LCD.SendToDisplay;
end;


//Taken from ScreenThief Delphi App available from delphi.about.com
//Used to snapshot a few pixels properlly
procedure ScreenShot(x : integer; y : integer; Width : integer; Height : integer; bm : TBitMap);
var
	dc: HDC; lpPal : PLOGPALETTE;
begin
{test width and height}
	if ((Width = 0) OR (Height = 0)) then exit;
	bm.Width := Width;
	bm.Height := Height;
{get the screen dc}
	dc := GetDc(0);
	if (dc = 0) then exit;
{do we have a palette device?}
	if (GetDeviceCaps(dc, RASTERCAPS) AND RC_PALETTE = RC_PALETTE) then
	begin
		{allocate memory for a logical palette}
		GetMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
		{zero it out to be neat}
		FillChar(lpPal^, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)), #0);
		{fill in the palette version}
		lpPal^.palVersion := $300;
		{grab the system palette entries}
		lpPal^.palNumEntries :=GetSystemPaletteEntries(dc,0,256,lpPal^.palPalEntry);
		if (lpPal^.PalNumEntries <> 0) then
		begin
			{create the palette}
			bm.Palette := CreatePalette(lpPal^);
		end;
		FreeMem(lpPal, sizeof(TLOGPALETTE) + (255 * sizeof(TPALETTEENTRY)));
	end;
	{copy from the screen to the bitmap}
	BitBlt(bm.Canvas.Handle,0,0,Width,Height,Dc,x,y,SRCCOPY);
	{release the screen dc}
	ReleaseDc(0, dc);
end; (* ScreenShot *)

end.
