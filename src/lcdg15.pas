unit lcdg15;

{

Copyright (C) 2006 smurfynet at users.sourceforge.net
This is free software distributed under the terms of the
GNU Public License.  See the file COPYING for details.
$Id: lcdg15.pas,v 0.3 2007/05/01 smurfy.de $

Changes:
v0.4:
 Modified TLcdG15.Create method.  Split most off into .Connect, and added
 various properties to TLcdG15.  There should be no reason for Asserts.  Also,
 handle multiple user interaction errors such as unplugging the keyboard.
 Cleaned up USES.
v0.3:
 modifications for new Wrapper-DLL - Olaf Stieleke
v0.2:
 added support for configure and softbuttonscallback
v0.1:
 initial release support main functions

}



interface

uses
	Windows, Classes, Graphics;

{///************************************************************************ }
{/// lgLcdDeviceDesc }
{///************************************************************************ }


type
	lgLcdDeviceDesc = record
    Width: LongInt;
    Height: LongInt;
    Bpp: LongInt;
    NumSoftButtons: LongInt;
  end {lgLcdDeviceDesc};

{///************************************************************************ }
{/// lgLcdBitmap }
{///************************************************************************ }

const
  LGLCD_BMP_FORMAT_160x43x1 = $00000001;
const
  LGLCD_BMP_WIDTH = (160);
const
  LGLCD_BMP_HEIGHT = (43);


type
  PlgLcdBitmapHeader = ^lgLcdBitmapHeader;
  lgLcdBitmapHeader = record
    Format: LongInt;
  end {lgLcdBitmapHeader};

type
  lgLcdBitmap160x43x1 = record
    hdr: LGLCDBITMAPHEADER;
    pixels : array[0..6879] of byte; { LGLCD_BMP_WIDTH * LGLCD_BMP_HEIGHT}
  end {lgLcdBitmap160x43x1};

{/// Priorities }
const
  LGLCD_PRIORITY_IDLE_NO_SHOW = (0);
const
  LGLCD_PRIORITY_BACKGROUND = (64);
const
  LGLCD_PRIORITY_NORMAL = (128);
const
  LGLCD_PRIORITY_ALERT = (255);
const
	LGLCD_SYNC_UPDATE = $80000000;

{///************************************************************************ }
{/// Callbacks }
{///************************************************************************ }

// currently not in use  

type lgLcdOnConfigureCB = function (connection:integer;const pContext:Pointer):dword;stdcall;
type lgLcdOnSoftButtonsCB = function(device:integer;dwButtons:dword;pContext:pointer):dword;stdcall;


{///************************************************************************ }
{/// lgLcdConnectContext }
{///************************************************************************ }


type
  lgLcdConfigureContext = record
{/// Set to NULL if not configurable }
    configCallback: LGLCDONCONFIGURECB;
    configContext: pointer;
  end {lgLcdConfigureContext};

type
  lgLcdConnectContextA = record
{/// "Friendly name" display in the listing }
    appFriendlyName: pchar;
{/// isPersistent determines whether this connection persists in the list }
    isPersistent: Bool;
{/// isAutostartable determines whether the client can be started by }
{/// LCDMon }
		isAutostartable: Bool;
    onConfigure: lgLcdConfigureContext;
{/// --> Connection handle }
    connection: Integer;
  end {lgLcdConnectContextA};


{///************************************************************************ }
{/// lgLcdOpenContext }
{///************************************************************************ }

type
  lgLcdSoftbuttonsChangedContext = record
{/// Set to NULL if no softbutton notifications are needed }
    softbuttonsChangedCallback: LGLCDONSOFTBUTTONSCB;
    softbuttonsChangedContext: Pointer;
  end {lgLcdSoftbuttonsChangedContext};

type
  lgLcdOpenContext = record
    connection: Integer;
{/// Device index to open }
    index: Integer;
		onSoftbuttonsChanged: LGLCDSOFTBUTTONSCHANGEDCONTEXT;
{/// --> Device handle }
    device: Integer;
  end {lgLcdOpenContext};


{///************************************************************************ }
{/// Exported functions }
{///************************************************************************ }

//Calling convention now cdecl, not stdcall anymore - OST, 01.05.2007
function lgLcdInit:dword; cdecl;
procedure lgLcdDeInit;cdecl;
function lgLcdEnumerate(connection,index:integer; var lgLcdDeviceDesc:lgLcdDeviceDesc): word; cdecl;
function lgLcdClose(device:integer):dword;cdecl;
function lgLcdConnectA(var lgLcdConnectContextA: lgLcdConnectContextA):dword;cdecl;
function lgLcdDisconnect(connection:integer):dword;cdecl;
function lgLcdOpen(var lgLcdOpenContext:lgLcdOpenContext):dword;cdecl;
function lgLcdUpdateBitmap(device:integer; lgLcdBitmapHeader:PlgLcdBitmapHeader;priority:dword):dword;cdecl;
function lgLcdReadSoftButtons(device:integer; var button:dword):dword;cdecl;


{///************************************************************************ }
{/// Delphi Helper Class  }
{///************************************************************************ }

function TLcdG15LcdOnSoftButtonsCB(device:integer;dwButtons:dword;pContext:pointer):dword; stdcall;
function TLcdG15LcdOnConfigureCB(connection:integer;const pContext:Pointer):dword;stdcall;

type TOnSoftButtonsCB = procedure(dwButtons:integer) of Object;
type TOnConfigureCB = procedure() of Object;

//Error codes1=init, 2=connect, 3=enumerate, 4=open.
type TOnError = procedure(ID:byte) of Object;


type TLcdG15 = class(TObject)
	private
		LCanvas : TCanvas;
		LOpenContext : lgLcdOpenContext;
		LOnSoftButtonsCB : TOnSoftButtonsCB;
		LOnConfigureCB : TOnConfigureCB;
		LOnError : TOnError;
		function GetConnected : boolean;
	public
		property OnSoftButtons : TOnSoftButtonsCB read LOnSoftButtonsCB write LOnSoftButtonsCB;
		property OnConfigure : TOnConfigureCB read LOnConfigureCB write LOnConfigureCB;
		property OnError : TOnError read LOnError write LOnError;
		property LCDCanvas : TCanvas read LCanvas write LCanvas;
		property Connected : boolean read GetConnected;
		constructor Create(); reintroduce;
		destructor Destroy(); override;
		function Connect(
			//Name of your app
			ApplicationName:string;
			//Does this app stay in the LCD Manager?
			isPersistent:Bool;
			//Does your LCD Manager run this?  Assumes isPersistent, so turn it on if you use this
			isAutostartable:Bool;
			//If you want to configure it.  Make sure OnConfigure is linked
			SupportConfigure:boolean = false
		) : boolean;
		procedure Disconnect;
		procedure SendToDisplay();
		procedure ClearDisplay();
		function GetButtonsPress():integer;
end;

implementation


{///************************************************************************ }
{/// Load Exported functions }
{///************************************************************************ }

//Changed calling convention and renaming of the imported DLL-Functions
//OST, 01.05.2007
function lgLcdEnumerate(connection,index:integer; var lgLcdDeviceDesc:lgLcdDeviceDesc): word; cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdEnumerateWrap';

function lgLcdInit:dword; cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdInitWrap';

procedure lgLcdDeInit;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdDeInitWrap';

function lgLcdClose(device:integer):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdCloseWrap';

function lgLcdConnectA(var lgLcdConnectContextA : lgLcdConnectContextA):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdConnectAWrap';

function lgLcdDisconnect(connection:integer):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdDisconnectWrap';

function lgLcdOpen(var lgLcdOpenContext:lgLcdOpenContext):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdOpenWrap';

function lgLcdUpdateBitmap(device:integer; lgLcdBitmapHeader:PlgLcdBitmapHeader;priority:dword):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdUpdateBitmapWrap';

function lgLcdReadSoftButtons(device:integer; var button:dword):dword;cdecl;
external 'lgLcdWrapper.dll' name 'lgLcdReadSoftButtonsWrap';


{///************************************************************************ }
{/// Delphi Helper Class  implementation}
{///************************************************************************ }

constructor TLcdG15.Create;
begin
	LCanvas := nil;
end;

function TLcdG15.Connect(
	ApplicationName:string;
	isPersistent:Bool;
	isAutostartable:Bool;
	SupportConfigure:boolean = false
) : boolean;
var ConnectContext : lgLcdConnectContextA;
		DeviceDescription : lgLcdDeviceDesc;
begin
	Result := true; //Assume true

	//init display
	if lgLcdInit() <> 0 then
	begin
		//Couldn't init, call error, don't bother going further.
		Result := false;
		if Assigned(OnError) then OnError(1);
		Exit;
	end;

	//init connect to display
	ConnectContext.appFriendlyName := pchar(ApplicationName);
	ConnectContext.isPersistent := isPersistent;
	ConnectContext.isAutostartable := isAutostartable;

	if (SupportConfigure) then
	begin
	 ConnectContext.onConfigure.configCallback := TLcdG15LcdOnConfigureCB;
	 ConnectContext.onConfigure.configContext := self;
	end
	else
	begin
	 ConnectContext.onConfigure.configCallback := nil;
	 ConnectContext.onConfigure.configContext := nil;
	end;

	ConnectContext.connection := -1;

	//connect
	if (lgLcdConnectA(ConnectContext) <> 0) or
		(ConnectContext.Connection = -1) then
	begin
		//Couldn't connect, call error, try to deInit, exit
		if Assigned(OnError) then OnError(2);
		Result := false;
		try
			lgLcdDeInit;
		finally
			//Not sure if I can throw Exit here....who knows
		end;
		Exit;
	end;

	//enum display. connect to display 0 !
	if (lgLcdEnumerate(ConnectContext.connection,0,DeviceDescription) <> 0) then
	begin
		//Can't connect, call error, try to deinit, exit
		if Assigned(OnError) then OnError(3);
		Result := false;
		try
			lgLcdDeInit;
		finally
			//
		end;
		Exit;
	end;

	LOpenContext.connection := ConnectContext.connection;
	LOpenContext.index := 0;
	LOpenContext.onSoftbuttonsChanged.softbuttonsChangedCallback := TLcdG15LcdOnSoftButtonsCB;
	LOpenContext.onSoftbuttonsChanged.softbuttonsChangedContext := self;
	LOpenContext.device := -1;

	if (lgLcdOpen(LOpenContext) <> 0) or
		(LOpenContext.device = -1) then
	begin
		//Can't connect, call error, try to deinit, exit
		if Assigned(OnError) then OnError(4);
		Result := false;
		try
			lgLcdDeInit;
		finally
			//
		end;
	end;

end;

destructor TLcdG15.Destroy();
begin
	try
		Disconnect;
	finally
		//
	end;
end;

procedure TLcdG15.Disconnect;
begin
	lgLcdClose(LOpenContext.device);
	lgLcdDeInit;
end;

function TLcdG15.GetConnected : boolean;
begin
	Result := Not(LOpenContext.device = -1);
end;

procedure TLcdG15.SendToDisplay();
var i,it,x2:integer;
		tmp : tcolor;
		bmp : lgLcdBitmap160x43x1;
		//i2:int64;
begin
	if not Connected then exit;
	x2:=0;
	for it:= 0 to 43 -1 do
	begin
		for i:= 0 to 160 -1 do
		begin
			tmp :=  LCanvas.Pixels[i,it];
			if tmp <> $ffffff then
				bmp.pixels[x2] := 128
			else
				bmp.pixels[x2] := 0;
			inc(x2);
		end;
	end;
	bmp.hdr.Format := LGLCD_BMP_FORMAT_160x43x1;
	lgLcdUpdateBitmap(LOpenContext.device,@bmp.hdr,LGLCD_SYNC_UPDATE or 128);
end;

procedure TLcdG15.ClearDisplay();
var
	bmp : lgLcdBitmap160x43x1;
	i : integer;
begin
	if not Connected then exit;
	for i:= 0 to 160*43 -1 do
		bmp.pixels[i] := 0;

	bmp.hdr.Format := LGLCD_BMP_FORMAT_160x43x1;
	lgLcdUpdateBitmap(LOpenContext.device,@bmp.hdr,LGLCD_SYNC_UPDATE or 128);
end;

function TLcdG15.GetButtonsPress():integer;
var button : dword;
begin
	Result:=0;
	if not Connected then exit;
	lgLcdReadSoftButtons(LOpenContext.device,button);
	Result :=  button;
end;

{///************************************************************************ }
{/// Delphi Callback helper  implementation}
{///************************************************************************ }


function TLcdG15LcdOnSoftButtonsCB(device:integer;dwButtons:dword;pContext:pointer):dword;stdcall;
begin
	Result:=0;
	if (pContext <> nil) then
	begin
		if (assigned(TLcdG15(pContext).LOnSoftButtonsCB)) then
		begin
			TLcdG15(pContext).LOnSoftButtonsCB( dwButtons);
		end;
	end;
end;

function TLcdG15LcdOnConfigureCB(connection:integer;const pContext:Pointer):dword;stdcall;
begin
	Result:=0;
	if (pContext <> nil) then
	begin
		if (assigned(TLcdG15(pContext).LOnConfigureCB)) then
		begin
			TLcdG15(pContext).LOnConfigureCB();
		end;
	end;
end;

end.
