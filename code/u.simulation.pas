unit u.simulation;

interface
  uses u.map, u.ants;

type
  TSimulation = record
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
  map.ants.addNewAndInit(24000, lrOwner);
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


end.
