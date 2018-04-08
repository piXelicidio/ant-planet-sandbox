unit u.utils;

interface

uses px.vec2d;

type

TRadial = record
  private
    step :single;
  public
    dirs :TVec2dArray;
    procedure Init( N:integer );
    function getDirIdx( angle : single ):integer;
    function getDir( angle : single):PVec2d;
    function getDirByIdx( idx :integer ):PVec2d;
    function fixIdx( idx :integer ):integer;
    function IdxToAngle( idx : integer ):single;
end;

implementation

{ TRadial }

function TRadial.fixIdx(idx: integer): integer;
begin
  if idx>0 then result := idx mod length(dirs)
    else result := length(dirs) + (idx mod length(dirs));
end;

function TRadial.GetDir(angle: single): PVec2d;
begin
  result := @dirs[GetDirIdx(angle)];
end;

function TRadial.getDirByIdx(idx: integer): PVec2d;
begin
  idx :=  idx mod length(dirs);
  if idx<0  then idx := length(dirs) + idx;
  result := @dirs[idx];
end;

function TRadial.GetDirIdx(angle: single): integer;
var
  s:single;
begin
  result := round( angle / step ) mod length(dirs);
  if result< 0 then result := length(dirs) + result;
  if (result<0) or (result>(high(dirs))) then
  begin
    writeln('cascara');
  end;
end;

function TRadial.IdxToAngle(idx: integer): single;
begin
  result := fixIdx( idx ) * step;
end;

procedure TRadial.Init(N: integer);
var
  i: Integer;
begin
    setLength(dirs, N);
    step := (2*pi/N);
    for i := 0 to N-1 do
    begin
      dirs[i] := vec( cos( i * step  ), sin( i * step ) );
    end;
end;

end.
