unit u.gui;

interface
  uses
    px.guiso,
    system.Classes,
    u.simcfg
    ;


type
  TAppGui = class
    private
    protected
      fMain :TGuisoScreen;

      fScreen :TGuisoScreen; //current screen;
    public
      lblFPS :TGuisoLabel;
      lblNumAnts :TGuisoLabel;
      radioTool :TGuisoRadioGroup;
      checkPheroms :TGuisoCheckBox;
      MainPanel :TGuisoPanel;
      procedure init;
      constructor create;
      destructor Destroy;override;
      property screen:TGuisoScreen read fScreen;
  end;


implementation

{ TAppGui }

constructor TAppGui.create;
begin
  fMain := TGuisoScreen.create;
  fScreen := fMain;
end;

destructor TAppGui.Destroy;
begin
  fMain.free;
  inherited;
end;

procedure TAppGui.init;
var
  strs :TStringList;
begin
  //main;
  MainPanel := TGuisoPanel.create;
  MainPanel.setWH(120, 700 );
  fMain.addChild(MainPanel);
  MainPanel.setXY(0,0);

  lblFPS := TGuisoLabel.create;
  lblFPS.setWH(100, 20);
  lblFPS.TextAlignX := 0;
  MainPanel.addChild(lblFPS, 0.5, 0);

  lblNumAnts := TGuisoLabel.create;
  lblNumAnts.TextAlignX := 0;
  MainPanel.addChildBellow(lblNumAnts, lblFPS, true);

  strs := TStringList.Create;
  strs.Add('block');
  strs.Add('grass');
  strs.Add('cave');
  strs.Add('food');
//  strs.Add('portal');
  strs.add('remove');
  radioTool := TGuisoRadioGroup.create(strs, MainPanel.width-20, 30);
  MainPanel.addChildBellow(radioTool, lblNumAnts);

  checkPheroms := TGuisoCheckBox.create;
  MainPanel.addChildBellow( checkPheroms, radioTool );
  checkPheroms.Text := 'Pheroms';
  checkPheroms.setWH( 100, 30 );

end;

end.
