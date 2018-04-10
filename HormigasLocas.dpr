program HormigasLocas;
{$IFDEF DEBUG}
{$APPTYPE CONSOLE}
{$ENDIF}

{$R *.res}

uses
  System.SysUtils,
  sdl2,
  px.vec2d, system.math,
  px.sdl in '..\UnitsLib\pxsdl\px.sdl.pas',
  u.ants in 'code\u.ants.pas',
  u.simulation in 'code\u.simulation.pas',
  u.map in 'code\u.map.pas',
  u.cell in 'code\u.cell.pas',
  u.camview in 'code\u.camview.pas',
  u.MainApp in 'u.MainApp.pas',
  u.simcfg in 'code\u.simcfg.pas',
  u.utils in 'code\u.utils.pas',
  u.frametimer in 'code\u.frametimer.pas';

begin
  mainApp.Start;
end.
