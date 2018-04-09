unit u.cell;

interface
  uses
    u.simcfg, u.ants, px.sdl,  sdl2;

type
  TCellTypes = (ctFood, ctCave, ctGrass, ctBlock, ctGround); //ctBlock and ctGround don't need class
  //add more ant interests between ctFood and ctCave;
  TAntInterests = ctFood..ctCave;

  CCell = class of TCell;
  TCell = class
    private
      fCellType :TCellTypes;
      fImg :PSprite;
      fDrawOverlay :boolean;
      fNeedDestroyWhenRemoved :boolean;
    public
      constructor create;
      procedure affectAnt(const ant :TAnt );virtual;abstract;
      procedure draw(x,y:integer);virtual;
      property NeedDestroyWhenRemoved:boolean read fNeedDestroyWhenRemoved;
      property DrawOverlay:boolean read fDrawOverlay;
      property cellType :TCellTypes read fCellType;
  end;

  TGrass = class(TCell)
   public
    procedure affectAnt(const ant :TAnt );override;
  end;

  TInterestingCell = class(TCell)
    private
    public
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
      fOneGrass :TGrass;
      fFoodImg :TSprite;
      fCaveImg :TSprite;
      fGrassImg: TSprite;
    public
      procedure init;
      procedure finalize;
      function newFood:TFood;  //you responsible to free it later
      function getCave:TCave;  //owned by this class
      function getGrass:TGrass; //owned '' '' ''
  end;

var
  cellFactory : TCellFActory;

implementation


{ TGrassCell }

procedure TGrass.AffectAnt(const ant: TAnt);
begin

end;

{ TFood }

procedure TFood.AffectAnt(const ant: TAnt);
begin

end;

constructor TFood.create;
begin
  fCellType := ctFood;
end;

{ TCave }

procedure TCave.AffectAnt(const ant: TAnt);
begin

end;

constructor TCave.create;
begin
  fCellType := ctCave;
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
  fCaveImg := sdl.newSprite( sdl.loadTexture('images\cave.png'));
  fGrassImg := sdl.newSprite( sdl.loadTexture('images\grass01.png'));
  fOneCave := TCave.create;
  fOneCave.fNeedDestroyWhenRemoved := false;
  fOneCave.fImg := @fCaveImg;
  fOneGrass := TGrass.create;
  fOneGrass.fNeedDestroyWhenRemoved := false;
  fOneGrass.fImg := @fGrassImg;
end;

function TCellFactory.getCave: TCave;
begin
  result := fOneCave;
end;

function TCellFactory.getGrass: TGrass;
begin
  result := fOneGrass;
end;

function TCellFactory.newFood: TFood;
begin
  Result := TFood.create;
  Result.fNeedDestroyWhenRemoved := true;
  Result.fImg := @fFoodImg;
end;

initialization
  cellFactory := TCellFactory.Create;
finalization
  cellFactory.Free;
end.
