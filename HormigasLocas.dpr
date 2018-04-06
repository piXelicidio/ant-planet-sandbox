program HormigasLocas;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  sdl2,
  px.vec2d,
  px.sdl in '..\UnitsLib\pxsdl\px.sdl.pas',
  u.ants in 'code\u.ants.pas',
  u.simulation in 'code\u.simulation.pas',
  u.map in 'code\u.map.pas',
  u.cell in 'code\u.cell.pas',
  u.camview in 'code\u.camview.pas',
  u.MainApp in 'u.MainApp.pas',
  u.simcfg in 'code\u.simcfg.pas';

begin
  try
     mainApp.Start;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
