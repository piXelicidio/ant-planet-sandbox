unit u.simulation;

interface
  uses
    u.simcfg,
    u.map,
    u.ants;

type
  TSimulation = class
    public
      procedure init;
      procedure update;
      procedure draw;
  end;
var
  sim :TSimulation;
implementation

{ TSimulation }

procedure TSimulation.init;
begin
  map.init;
  map.ants.addNewAndInit(cfg.numAnts, lrOwner);
end;

procedure TSimulation.update;
begin
  //map.update;
  map.ants.update;
end;

procedure TSimulation.draw;
begin
  map.draw;
end;

initialization
  sim := TSimulation.Create;
finalization
  sim.Free;

end.
