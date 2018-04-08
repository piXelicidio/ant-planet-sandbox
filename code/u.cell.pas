unit u.cell;

interface
  uses
    u.simcfg, u.ants, px.sdl;

type
  TAntInterests = (aiFood, aiCave);
  TCellDrawMode = (dmFullCell, dmOverlay);

  CCell = class of TCell;
  TCell = class
    private
      fImg :TSprite;
      fDrawMode :TCellDrawMode;
    public
      procedure affectAnt(const ant :TAnt );virtual;abstract;
      procedure draw(x,y:integer);virtual;
  end;

  TGrassCell = class(TCell)
   public
    procedure AffectAnt(const ant :TAnt );override;
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
      procedure AffectAnt(const ant :TAnt);override;
  end;

  TFood = class(TInterestingCell)
    private
    public
      constructor create;
      procedure AffectAnt(const ant :TAnt);override;
  end;

  TCellFactory = class
    private
    public
      procedure init;
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

procedure TCell.draw;
begin
  sdl.drawSprite(fImg, x,y);
end;

{ TCellFactory }

procedure TCellFactory.init;
begin

end;

initialization
  cellFactory := TCellFactory.Create;
finalization
  cellFactory.Free;
end.
