unit px.vec2d;

interface

uses sysutils, system.math;

const
  singleMaxDifference = 0.000001;

type

  TVec2di = record
    x,y :integer;
    class operator equal(const a, b :TVec2di ):boolean;inline;
  end;

  { TVec2d }
  PVec2d = ^TVec2d;
  TVec2d = record
        x,y  :single;
      procedure add( ax, ay :single);overload;inline;
      procedure add(const v2 : TVec2d );overload;inline;
      procedure sub(const v2 : TVec2d );overload;inline;
      procedure scale( s : single ); inline;
      procedure invert;inline; //negate
      function pprint:string;
      procedure init( ax, ay:single );inline;
      function cross(const v2 :TVec2d ):single;inline; //cross product, return Z value.
      function dot(const v2 :TVec2d ):single;inline;   //dot product
      function len:single;inline;
      function lenSq:single;inline;
      function lenManhattan:single;inline;
      function normalized:TVec2d;inline;
      procedure normalize;inline;
      procedure rotate( rad :single );inline;
      function rotated( rad :single ):TVec2d;inline;
      function rounded:TVec2di;inline;
      function floored:TVec2di;inline;
      class operator add(const a, b: TVec2d):TVec2d;inline;
      class operator add(const a :TVec2d; s :single):TVec2d;inline;
      class operator add(s :string; const b :TVec2d):string;
      class operator subtract(const a, b: TVec2d):TVec2d;inline;
      class operator negative(const b :TVec2d):TVec2d;inline;
      class operator implicit(s :single ):TVec2d;inline;
      class operator implicit(const a :TVec2d ):string;
      class operator multiply(const a, b: TVec2d):TVec2d;inline;
      class operator multiply(const a :TVec2d; s :single):TVec2d;inline;
      class operator equal(const a, b :TVec2d ) :boolean;inline;
      //TODO: projections
  end;

  TVec2dArray = array of TVec2d;
  TPVec2dArray = array of PVec2d;

  function vec( ax, ay :single ):TVec2d;overload;inline;
  function vecDir( angle : single):TVec2d;inline;

  procedure vecRotate(vecs :PVec2d; count :integer; rad:single);overload;
  procedure vecRotate(const vecs :TVec2DArray; rad : single );overload;
  procedure vecRotate(const vecs :TPVec2dArray; rad : single);overload;
  function vecAverage(vecs :PVec2d; count :integer):TVec2d;overload;
  function vecAverage(const vecs :TVec2DArray ):TVec2d;overload;
//TODO array of PVec2d


implementation

function vec( ax, ay :single ):TVec2d;
begin
  result.x := ax;
  result.y := ay;
end;


function vecDir(angle: single): TVec2d;
begin
  result.x := cos(angle);
  result.y := sin(angle);
end;

{rotate an array of vectors}
procedure vecRotate(const vecs :TVec2DArray;  rad :single );
begin
  if length(vecs) > 0 then vecRotate(@vecs[0], length(vecs), rad );
end;

{rotate a mem consecutive group of vectors starting with a pointer to the first one
 Why use this instead of calling each vector rotate:
 Because the calc of Sin(rad) and Cos(rad) is made only once here.
 tested and resulted: x47 times faster rotating an array of 1000 vectors 10,000 times.
}
procedure vecRotate(vecs :PVec2d;  count :integer; rad:single);
var
  i :integer;
  tx :single;
  v  :PVec2d;
  CosRad, SinRad :single;
begin
  v := vecs;
  cosRad := cos(rad);
  sinRad := sin(rad);
  for i := 1 to count do
  begin
    tx := v.x;
    v.x := v.x * cosRad - v.y * sinRad;
    v.y := tx * sinRad + v.y * cosRad;
    inc(v);
  end;
end;

{Rotate vectors in array of pointer to vectros PVec2d }
procedure vecRotate(const vecs:TPVec2dArray; rad : single);overload;
var
  cosRad: single;
  sinRad: single;
  i: Integer;
  tx:single;
  v :PVec2d;
begin
  cosRad := cos(rad);
  sinRad := sin(rad);
  for i := 0 to High(vecs) do
  begin
    v := vecs[i];
    tx := v.x;
    v.x := v.x * cosRad - v.y * sinRad;
    v.y := tx * sinRad + v.y * cosRad;
  end;
end;

{calc average of a mem consecutive group of vectors starting with a pointer to the first one }
function vecAverage(vecs :PVec2d; count :integer):TVec2d;overload ;
var
  i: Integer;
  sum: TVec2d;
begin
  sum := vec(0.0,0.0);
  for i := 1 to count do
  begin
    sum.add(vecs^);
    inc(vecs);
  end;
  Result.x := sum.x / count;
  Result.y := sum.y / count;
end;

{calc average of vectors in array}
function vecAverage(const vecs :TVec2DArray ):TVec2d;overload;
begin
  if Length(vecs)>0 then vecAverage(@vecs[0], length(vecs) );
end;

{ TVec2d }

class operator TVec2d.add(s :string; const b :TVec2d):string;
begin
  result := s + b.pprint;
end;

class operator TVec2d.implicit(const a :TVec2d ):string;
begin
  result := a.pprint;
end;

class operator TVec2d.negative(const  b :TVec2d):TVec2d;
begin
  result.x := -b.x;
  result.y := -b.y;
end;

procedure TVec2d.rotate( rad :single );
var
  tx :single;
  cosRad: single;
  sinRad: single;
begin
  tx := x;
  cosRad := cos(rad); sinRad := sin(rad);
  x := x * cosRad - y * sinRad;
  y := tx * sinRad + y * cosRad;
end;

function TVec2d.rotated( rad :single ):TVec2d;
var
  cosRad, sinRad :single;
begin
  cosRad := cos(rad); sinRad := sin(Rad);
  result.x := x * cosRad - y * sinRad;
  result.y := x * sinRad + y * cosRad;
end;


function TVec2d.rounded: TVec2di;
begin
  result.x := round(x);
  result.y := round(y);
end;


function TVec2d.normalized:TVec2d;
var
  l :single;
begin
  l := len;
  result := vec( x/l, y/l);
end;

procedure TVec2d.normalize;
var
  l :single;
begin
  l := len;
  x :=  x/l;
  y :=  y/l;
end;


function TVec2d.len:single;
begin
  result := sqrt( x*x + y*y );
end;

function TVec2d.lenSq:single;
begin
  result := x*x + y*y;
end;

function TVec2d.lenManhattan:single;
begin
  result := abs(x) + abs(y);
end;

function TVec2d.dot(const v2 :TVec2d ):single;
begin
  result := x * v2.x + y * v2.y;
end;

procedure TVec2d.add(ax, ay: single);
begin
  x := x + ax;
  y := y + ay;
end;

procedure TVec2d.add(const v2: TVec2d);
begin
  x := x + v2.x;
  y := y + v2.y;
end;

function TVec2d.cross(const v2 :TVec2d ):single;
begin
  result := x * v2.y - y * v2.x;
end;

procedure TVec2d.init( ax, ay:single );
begin
  x := ax; y := ay;
end;

procedure TVec2d.invert;
begin

end;

function TVec2d.pprint: string;
begin
  result := '(' +  FloatToStr(x) + ',' + FloatToStr(y) + ')'
end;

class operator TVec2d.multiply(const a, b: TVec2d):TVec2d;
begin
  result.x := a.x * b.x;
  result.y := a.y * b.y;
end;

procedure TVec2d.scale(s: single);
begin
  x := x * s;
  y := y * s;
end;

procedure TVec2d.sub(const v2: TVec2d);
begin
  x := x - v2.x;
  y := y - v2.y;
end;

class operator TVec2d.subtract(const a, b: TVec2d): TVec2d;
begin
  result.x := a.x - b.x;
  result.y := a.y - b.y;
end;

class operator TVec2d.add(const a, b: TVec2D): TVec2d;
begin
  result.x := a.x + b.x;
  result.y := a.y + b.y;
end;

class operator TVec2d.add(const a :TVec2d; s :single):TVec2d;
begin
  Result.x := a.x + s;
  Result.y := a.y + s;
end;

class operator TVec2d.implicit(s :single ):TVec2d;
begin
  result.x := s;
  result.y := s;
end;

class operator TVec2d.equal(const a, b :TVec2d ) :boolean;
begin
  result := (abs(a.x - b.x) < singleMaxDifference) and (abs(a.y - b.y) < singleMaxDifference);
end;

function TVec2d.floored: TVec2di;
begin
  result.x := floor(x);
  result.y := floor(y);
end;

class operator TVec2d.multiply (const a :TVec2d; s :single):TVec2d;
begin
  result.x := a.x * s;
  result.y := a.y * s;
end;

{ TVec2di }

class operator TVec2di.equal(const a, b: TVec2di): boolean;
begin
  result := (a.x = b.x) and (a.y = b.y );
end;

end.

