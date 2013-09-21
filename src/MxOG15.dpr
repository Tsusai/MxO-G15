program MxOG15;

uses
  Forms,
  Windows,
  Main in 'Main.pas' {Form1},
  lcdg15 in 'lcdg15.pas',
  Dates in 'Dates.pas';

{$R *.res}

var
	ExistingHandle : THandle;
begin
	ExistingHandle := FindWindow('TForm1','MxO G15 Applet');
	if ExistingHandle = 0 then
	begin
		Application.Initialize;
		Application.MainFormOnTaskbar := True;
		Application.ShowMainForm:=False;
		Application.Title := 'MxO G15 Applet Beta 3';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
	end else
	begin
		SetForegroundWindow(ExistingHandle);
	end;
end.
