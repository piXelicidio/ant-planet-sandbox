unit u.cell;

interface
  uses
    u.simcfg, u.ants, px.sdl,  sdl2;

type
  TAntInterests = (aiFood, aiCave);

  CCell = class of TCell;
  TCell = class
    private
      fImg :PSprite;
      fDrawOverlay :boolean;
    public
      constructor create;
      procedure affectAnt(const ant :TAnt );virtual;abstract;
      procedure draw(x,y:integer);virtual;
      property DrawOverlay:boolean read fDrawOverlay;
  end;

  TGrassCell = class(TCell)
   public
    procedure affectAnt(const ant :TAnt );override;
  end;

  TInterestingCell = class(TCell)
    private
      fCellType : TAntInterests;
    public
      property cellType :TAntInterests read fCellType;
  end;

  TCave = class(TInterestingCell)
    private
    public
      constructor create;
      procedure affectAnt(const ant :TAnt);override;
  end;

  TFood = class(TInterestingCell)
    private
    public
      constructor create;
      procedure affectAnt(const ant :TAnt);override;
  end;

  TCellFactory = class
    private
      fOneCave :TCave;
      fFoodImg :TSprite;
      fCaveImg :TSprite;
    public
      procedure init;
      procedure finalize;
      function newFood:TFood;  //you responsible to free it later
      function newCave:TCave;  //owned by this class
  end;

var
  cellFactory : TCellFActory;

implementation


{ TGrassCell }

procedure TGrassCell.AffectAnt(const ant: TAnt);
begin

end;

{ TFood }

procedure TFood.AffectAnt(const ant: TAnt);
begin

end;

constructor TFood.create;
begin
  fCellType := aiFood;
end;

{ TCave }

procedure TCave.AffectAnt(const ant: TAnt);
begin

end;

constructor TCave.create;
begin
  fCellType := aiCave;
end;

{ TCell }

constructor TCell.create;
begin
  fDrawOverlay := false;
end;

procedure TCell.draw;
begin
  sdl.drawSprite(fImg^ , x,y);
end;

{ TCellFactory }

procedure TCellFactory.finalize;
begin
  fOneCave.Free;
end;

procedure TCellFactory.init;
begin
  fFoodImg := sdl.newSprite( sdl.loadTexture('images\food01.png'));
  fCaveImg := sdl.newSprite( sdl.loadTexture('images\cave01.png'));
  fOneCave := TCave.create;
  fOneCave.fImg := @fCaveImg;
end;

function TCellFactory.newCave: TCave;
begin
  result := fOneCave;
end;

function TCellFactory.newFood: TFood;
begin
  Result := TFood.create;
  Result.fImg := @fFoodImg;
end;

initialization
  cellFactory := TCellFactory.Create;
finalization
  cellFactory.Free;
end.
