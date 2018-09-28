unit px.sdl;

interface

uses
  sdl2, sdl2_image, sdl2_ttf,
  sysutils, generics.collections;

type

  TSdlConfig = record
    window : record
      title :string;
      w  :SInt32 ;
      h  :SInt32 ;
      flags :UInt32;
      fullScreenType :cardinal;
      fullScreen :boolean;
    end;
    subsystems : UInt32; //  SDL_INIT_... flags
    RenderDriverIndex :SInt32;
    RenderFlags :UInt32;
    imgFlags :SInt32;
    defaultFont :string;
    defaultFontSize :integer;
    basePath :string;
    savePath_org :string;
    savePath_app :string;
  end;



   // using reference to procedure callbacks can be annonymos functions,
   // regular procedures or procedure of object, as I unduerstand :)_
  TProc = reference to procedure;
  TEventKeypress = reference to procedure(const keyEvent :TSDL_KeyboardEvent);
  TEventMouseMove = reference to procedure(const motion : TSDL_MouseMotionEvent );
  TEventMouseButton = reference to procedure(const button : TSDL_MouseButtonEvent );
  TEventMouseWheel = reference to procedure(const wheel : TSDL_MouseWheelEvent );
  TEventUserQuit  = reference to procedure(var isOkToQuit:boolean );
  TEventSDL = reference to procedure(const event :TSDL_Event);


  //  TProc = procedure of object;

  PSprite = ^TSprite;
  TSprite = record
    srcTex      :PSDL_Texture;
    srcRectPtr  :PSDL_Rect;  //can be nil to take entire texture, or point to the next field:
    srcRect     :TSDL_Rect;  // the actual rect that srcRectPtr should point to
    dstRect     :TSDL_Rect;  //position and dimentions to draw;
    center      :TSDL_Point;  //pivot point
  end;

  PBitmapFont = ^TBitmapFont;
  TBitmapFont = record
    srcTex        :PSDL_Texture;
    srcFont       :PTTF_Font;
    asciiSprites  :array[0..255] of TSDL_Rect;
    texW, texH :integer;
    maxW, maxH :integer;
  end;


type


  Tsdl = class
    type
      //TODO: textures in StringList? and check to no reload same texturet twice?
      TTextureList = TList<PSDL_Texture>;
      TFontList = TList<PBitmapFont>;
    private
      fStarted :boolean;
      fBasePath :string;
      fPrefPath :string;

      fWindow :PSDL_Window;
      fWinTitle :string;
      fTitleFPS :boolean;
      fFullScreen :boolean;
      fFullScreenType :cardinal; // SDL_WINDOW_FULLSCREEN_DESKTOP  or  SDL_WINDOW_FULLSCREEN
      fLogicalSize :TSDL_Point;
      fFixedFPS :integer;
      fFixedFrameTime :integer;
      fShowFrameProfiler :boolean;
      fDrawProfMax :integer;
      fUpdateProfMax :integer;

      fRend :PSDL_Renderer;
      fPixelWidth, fPixelHeight :LongInt;
      fTextures : TTextureList;
      fFonts    : TFontList;
      fFont     : PBitmapFont;
      fDefaultFont  :PBitmapFont;

      fMainLoop :TProc;
      fFrameCounter :Uint32;
      fAveFPS   :Uint32;
      fOnDraw :TProc;
      fOnLoad :TProc;
      fOnUpdate :TProc;
      fOnFinalize: TProc;
      fEvent  :TSDL_Event;
      fOnOtherEvents :TEventSDL;

      fOnKeyDown :TEventKeypress; //input
      fOnKeyUp   :TEventKeypress;
      fOnMouseMove :TEventMouseMove;
      fOnMouseDown :TEventMouseButton;
      fOnMouseUp   :TEventMouseButton;
      fOnMouseWheel :TEventMouseWheel;
      fOnUserQuit :TEventUserQuit;


      fTempRect :TSDL_Rect;
      fDemoX, fDemoY : LongInt;
      fDemoIncX, fDemoIncY : LongInt;
      fExitMainLoop: Boolean;

      procedure appMainLoop { <---------------------------------- MAIN LOOP };

      procedure defaultDraw;
      procedure defaultLoad;
      procedure defaultUpdate;
      procedure SetMainLoop( aMainLoop : TProc );
      procedure SetOnDraw(AValue: TProc);
      procedure SetonLoad(AValue: TProc);
      procedure SetonUpdate(AValue: TProc);
      procedure updateRenderSize;
      procedure SetonFinalize(const Value: TProc);
      procedure SetFont(const Value: PBitmapFont);
      function OpenFont( fileName:string; psize:integer ):PTTF_Font;
      function GetDefaultFont: PBitmapFont;
      function GetFFont: PBitmapFont;
      function getFullScreen: Boolean;
      procedure setFullScreen(const Value: Boolean);
      procedure setLogicalSize(const Value: TSDL_Point);

    public  //graphics
      procedure setColor( r, g, b:UInt8; a :UInt8 = 255 );overload;inline;
      procedure setColor(const sdlColor :TSDL_Color );overload;inline;
      procedure drawRect( x, y, w, h :SInt32; fill:boolean = false );inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer  );overload;//inline;
      procedure drawSprite(var sprite :TSprite; ax, ay :integer; angle :single);overload;//inline;
      function loadTexture( filename: string  ):PSDL_Texture;overload;
      function loadTexture( filename: string; out w,h:LongInt ):PSDL_Texture;overload;
      function newSprite( srcTex :PSDL_Texture; srcRectPtr:PSDL_Rect = nil):TSprite;overload;
      function newSprite( srcTex :PSDL_Texture; x, y, w, h :SInt32 ):TSprite;overload;
      procedure setCenterToMiddle(var aSprite:TSprite);

    public //fonts
      function createBitmapFont( ttf_FileName:string; fontSize :integer ):PBitmapFont;
      function drawText(s:string; x, y :integer; color :cardinal = $ffffff; alpha :byte = 255 ):TSDL_Rect;
      function textSize(s:string):TSDL_Point;  // the width and height;
      property Font:PBitmapFont read GetFFont write SetFont;
      property DefaultFont:PBitmapFont read GetDefaultFont;

    public //misc utils
      procedure convertGrayscaleToAlpha( surf :PSDL_Surface );
      function toAnsi(const s :string ):PAnsiChar;
      function toString( s :PAnsiChar ):string;
      function rect( ax, ay, aw, ah :integer ):TSDL_Rect;
      function color( r, g, b :byte; a: byte = 255 ):TSDL_Color;

    public //input
      property onKeyDown:TEventKeypress read fOnKeyDown write fOnKeyDown;
      property onKeyUp:TEventKeypress read fOnKeyUp write fOnKeyUp;
      property OnMouseMove:TEventMouseMove read fOnMouseMove write fOnMouseMove;
      property OnMouseDown :TEventMouseButton read fOnMouseDown write fOnMouseDown;
      property OnMouseUp   :TEventMouseButton read fOnMouseUp   write fOnMouseUp  ;
      property OnMouseWheel :TEventMouseWheel read fOnMouseWheel write fOnMouseWheel;
      property OnUserQuit :TEventUserQuit read fOnUserQuit write fOnUserQuit;
      property OnOtherEvents:TEventSDL read fOnOtherEvents write fOnOtherEvents;

    public  //application
      cfg :TSdlConfig;    //modify values of this record before start, optionally.

      procedure Start;  { <----- START }
      procedure Quit;

      procedure finalizeAll;
      procedure errorFatal;
      procedure errorMsg( s:string );
      procedure print( s:string );
      procedure showDriversInfo;
      procedure setFixedFPS( targetFPS :integer ); //0 for unlimited;
      procedure drawFrameProfiler( updateTime, drawTime:integer);

      constructor create;
      destructor Destroy;override;

      property window:PSDL_Window read fWindow;
      property fullScreen:Boolean read getFullScreen write setFullScreen;
      property fullScreenType:cardinal read fFullScreenType write fFullScreenType;
      property LogicalSize:TSDL_Point read fLogicalSize write setLogicalSize;
      property pixelWidth:LongInt read fPixelWidth;
      property pixelHeight:LongInt read fPixelHeight;
      property rend:PSDL_Renderer read fRend;
      property basePath:string read fBasePath write fBasePath;
      property ShowFrameProfiler:boolean read fShowFrameProfiler write fShowFrameProfiler;

      property MainLoop:TProc read fMainLoop write SetMainLoop;
      property frameCounter:cardinal read fFrameCounter;
      property FPS:cardinal read fAveFPS;
      property onLoad:TProc read fOnLoad write SetonLoad;
      property onUpdate:TProc read fOnUpdate write SetonUpdate;
      property onDraw:TProc read fOnDraw write SetOnDraw;
      property onFinalize:TProc read fOnFinalize write SetonFinalize;
  end;

var
  sdl :Tsdl;

implementation

{ Tsdl }

procedure Tsdl.appMainLoop;
var
  lastTick    :Uint32;
  frameStep   :Uint32;
  frameInterval :integer;
  currTick    :UInt32;
  titleFPS  :string;
  frameT_start :UInt32;
  frameT_afterUpdate :integer;
  frameT_afterDraw :integer;
  frameT_totalSpend :integer;
  frameT_neededDelay :integer;
  frameT_fix  :integer;
begin
  fExitMainLoop := false;
  lastTick := SDL_GetTicks;
  fFrameCounter := 0;
  frameStep     := 0;
  if fFixedFPS > 0 then frameInterval := fFixedFPS else frameInterval := 100;
  while fExitMainLoop = false do
  begin
    frameT_start := SDL_GetTicks;
    //process events
    while SDL_PollEvent(@fEvent) = 1 do
    begin
      case fEvent.type_ of
        SDL_KEYDOWN:  if assigned(fOnKeyDown) then fOnKeyDown(fEvent.key);
        SDL_KEYUP: if assigned(fOnKeyUp) then fOnKeyUp(fEvent.key);
        SDL_MOUSEMOTION: if assigned(fOnMouseMove) then fOnMouseMove(fEvent.motion);
        SDL_MOUSEBUTTONDOWN: if assigned(fOnMouseDown) then fOnMouseDown(fEvent.button);
        SDL_MOUSEBUTTONUP: if assigned(fOnMouseUp) then fOnMouseUp(fEvent.button);
        SDL_MOUSEWHEEL: if assigned(fOnMouseWheel) then fOnMouseWheel(fEvent.wheel);
        SDL_QUITEV :begin
                      fExitMainLoop := true;
                      if Assigned(fOnUserQuit) then fOnUserQuit(fExitMainLoop );
                    end

      else
        //Process Additional Events;
        if assigned(fOnOtherEvents) then fOnOtherEvents(fEvent);
      end
    end;
    //update

    fOnUpdate(); //TODO: calc dt when necessary
    frameT_afterUpdate := SDL_GetTicks;
    //draw;
    fOnDraw();
    frameT_afterDraw := SDL_GetTicks;

    //Delay for fixed time;
    frameT_totalSpend := frameT_afterDraw - frameT_start;
    frameT_neededDelay := fFixedFrameTime - frameT_totalSpend;

    {$IFDEF DEBUG}
    if fShowFrameProfiler then drawFrameProfiler( frameT_afterUpdate - frameT_start, frameT_afterDraw - frameT_afterUpdate );
    {$ENDIF}

    SDL_RenderPresent(fRend);

    //fixing some high precision error with SDL_Delay
    if frameT_neededDelay > 5 then SDL_Delay(frameT_neededDelay - 5);
    //CheckAgain:
    frameT_fix := SDL_GetTicks;
    frameT_neededDelay := fFixedFrameTime - (frameT_fix - frameT_start);
    if frameT_neededDelay>0 then
    begin
      //dirty precise delay
      repeat
        asm nop end;
      until SDL_GetTicks > (frameT_fix + frameT_neededDelay);
    end;


    //FPS calculation handling
    inc(fFrameCounter);
    inc(frameStep);
    if frameStep >= frameInterval then
    begin
      frameStep := 0;
      currTick := SDL_GetTicks;
      fAveFPS := (1000 * frameInterval) div (currTick - lastTick) ;
      lastTick := currTick;
      {titleFPS := fWinTitle +  ' FPS: ' + IntToStr(fAveFPS);
      if fTitleFPS then SDL_SetWindowTitle( fWindow, PAnsiChar(AnsiString(titleFPS))  );}
    end;


  end
end;

procedure Tsdl.defaultDraw;

begin
  setColor(0,0,0);
  SDL_RenderClear(fRend);
  setColor(255,255,255);
  drawRect(fDemoX, fDemoY, 100, 100);
end;

procedure Tsdl.defaultLoad;
begin
  fDemoX := 0; fDemoY:=0;
  fDemoIncX := 1; fDemoIncY := 1;
end;

procedure Tsdl.defaultUpdate;
begin
  fDemoX := fDemoX + fDemoIncX;
  fDemoY := fDemoY + fDemoIncY;
  if fDemoX < 0 then fDemoIncX := 1 else if fDemoX > fPixelWidth-100 then fDemoIncX := -1;
  if fDemoY < 0 then fDemoIncY := 1 else if fDemoY > fPixelHeight-100 then fDemoIncY := -1;
  SDL_Delay(1);
end;

function Tsdl.color(r, g, b, a: byte ): TSDL_Color;
begin
  result.r := r;
  result.g := g;
  result.b := b;
  result.a := a;
end;

procedure Tsdl.convertGrayscaleToAlpha(surf: PSDL_Surface);
var
  x, y: integer;
  pixel :^cardinal;
  newcolor :cardinal;
begin
  SDL_LockSurface( surf );
  for y := 0 to surf.h-1 do
  begin
    pixel := surf.pixels;
    inc(pixel, y * (surf.pitch div 4) );
    for x := 0 to surf.w-1 do
    begin
      newcolor := SDL_mapRGBA(surf.format, 255, 255, 255, (pixel^ and $ff));
      pixel^ := newcolor;
      inc(pixel)
    end;
  end;
  SDL_UnlockSurface( surf );
end;

constructor Tsdl.create;
begin
  fTitleFPS := true;
  fFrameCounter := 0;
  mainLoop:=appMainLoop;
  onLoad := defaultLoad;
  onDraw := defaultDraw;
  onUpdate := defaultUpdate;

  fTextures := TTextureList.Create;
  fFonts := TFontList.Create;
  setFixedFPS(0);
  fShowFrameProfiler := false;
end;

{
  Creates a bitmap font on the fly from a loaded TTF font file.
  Rasterize all the ASCII characters to a texture,
  for faster text drawing later.

  Returned PBitmapFont will be automatically diposed at the end of the application, you don't need to worry

}
function Tsdl.createBitmapFont(ttf_FileName: string;
  fontSize: integer): PBitmapFont;
const
  padding = 1;
var
  w  :integer;
  charWidth :array[0..255] of integer;
  i,j: Integer;
  c:word;   // as word jsut to avoid the integer overflow of the last inc(c) :)
  surf :PSDL_Surface;
  surfChar :PSDL_Surface;
  color :TSDL_Color;
  destRect :TSDL_Rect;
  sdlFont :PTTF_Font;
begin
  new(Result);
  fFonts.Add(Result);
  Result.maxW := 0;
  sdlFont := OpenFont( ttf_FileName , fontSize );
  if sdlFont = nil then
  begin
    errorMsg('Can''t open font '+ttf_FileName + ' ' + string( TTF_GetError ) );
    exit;
  end;
  Result.srcFont := sdlFont;
  //fFonts.Add( sdlFont );
  for c := 0 to 255 do
  begin
    //storing char widths and finding the max width
    TTF_SizeText(sdlFont, toAnsi(string(char(c))), @w, nil);
    if w > Result.maxW then Result.maxW := w;
    charWidth[c] := w;
  end;
  Result.maxH := TTF_FontHeight(sdlFont);
  Result.texW := (Result.maxW + padding) * 16;
  Result.texH := (Result.maxH + padding) * 16;
  //creating the surface to draw the char matrix of 16 x 16
  surf := SDL_CreateRGBSurfaceWithFormat(0, Result.texW, Result.texH, 32, SDL_PIXELFORMAT_RGBA8888);
  SDL_FillRect(surf, nil, $0 );
  c:= 0;
  color.r := 255;
  color.g := 255;
  color.b := 255;
  color.a := 0;
  for j := 0 to 15 do
    for i := 0 to 15 do
      begin
        if c > 0 then
        begin
          //Rendering a single character to a temporary Surface
          surfChar := TTF_RenderText_Blended(sdlFont, toAnsi(string(char(c))), color );
          //bliting the character to our big surface matrix
          destRect := sdl.Rect(i * (Result.maxW + padding), j * (Result.maxH + padding), charWidth[c], Result.maxH);
          Result.asciiSprites[c] := destRect;
          SDL_BlitSurface(surfChar, nil, surf,  @destRect  );
          SDL_FreeSurface(surfChar);
        end;
        inc(c);
      end;
  //to fix the problem with alpha premultiplied od TTF_RenderText_Blended
  //we get the image as a grayscale mask and convert the intensity to alpha channel
  sdl.ConvertGrayscaleToAlpha( surf );
  //convert to texture;
  Result.srcTex := SDL_CreateTextureFromSurface(sdl.rend, surf);
  SDL_FreeSurface(surf);
  TTF_CloseFont(sdlFont);
end;

destructor Tsdl.destroy;
begin

end;

procedure Tsdl.finalizeAll;
var
  i:integer;
begin
  if Assigned(fOnFinalize)  then fOnFinalize();

  for i:=0 to fTextures.Count-1 do
  begin
    SDL_DestroyTexture( fTextures.Items[i] );
  end;
  fTextures.Free;
  for i:=0 to fFonts.Count-1 do
  begin
    if assigned(fFonts.Items[i] ) then  dispose(fFonts.Items[i] );
  end;
  fFonts.Free;
  SDL_DestroyRenderer(fRend);
  SDL_DestroyWindow(fWindow);

  TTF_Quit;
  IMG_Quit;
  SDL_Quit;
end;

function Tsdl.GetDefaultFont: PBitmapFont;
begin
  result := @fDefaultFont;
end;

function Tsdl.GetFFont: PBitmapFont;
begin
  Result := @fFont;
end;

function Tsdl.getFullScreen: Boolean;
begin
  Result := fFullScreen;
end;

procedure Tsdl.Start;
var
  rendInfo :TSDL_RendererInfo;
  wh :TSDL_Point;
begin
  //initializaitons
  fStarted := true;
  //fBasePath := string(PAnsiChar(SDL_GetBasePath));  getcurrentdir
  if cfg.basePath='' then  fBasePath := toString( SDL_GetBasePath ) else fBasePath := cfg.basePath;
  fPrefPath := string( SDL_GetPrefPath(toAnsi(cfg.savePath_org), toAnsi(cfg.savePath_app)) );
  if fPrefPath='' then ;

  if SDL_Init(cfg.subsystems) < 0 then
  begin
    errorFatal;
    exit;
  end else
  begin
    if IMG_Init(cfg.imgFlags) <> cfg.imgFlags then
        errorMsg('Failed to init image format support');

    fWinTitle := cfg.window.title;
    fWindow := SDL_CreateWindow(toAnsi(fWinTitle), SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, cfg.window.w, cfg.window.h, cfg.window.flags );
    if fWindow = nil then errorFatal;
    fRend := SDL_CreateRenderer(fWindow, cfg.RenderDriverIndex, cfg.RenderFlags);
    if fRend = nil then errorFatal;
    wh.x := fWindow.w;
    wh.y := fWindow.h;
    setLogicalSize(wh);

    fFullScreenType := cfg.window.fullScreenType;
    setFullScreen( cfg.window.fullScreen );


    SDL_GetRendererInfo(fRend,@rendInfo);
    print('Renderer: '+ string(rendInfo.name));
    updateRenderSize;


    //font
    if TTF_Init()<>0 then
    errorMsg('Failed font support: ' + string( TTF_GetError() ) );

    fDefaultFont := createBitmapFont(cfg.defaultFont, cfg.defaultFontSize);
    if fDefaultFont.srcFont = nil then
    begin
      errorMsg('TTF_OpenFont : ' + string(TTF_GetError()) );
    end;
    fFont := fDefaultFont;

  end;
  //Load
  fOnLoad;
  //run applicaiton
  fMainLoop;
  //finalize app
  finalizeAll;
end;

//typecast convert... a Delphi String to PAnsiChar expected by every SDL function
function Tsdl.toAnsi(const s: string): PAnsiChar;
begin
  Result := PAnsiChar(AnsiString(s));
end;

function Tsdl.toString(s: PAnsiChar): string;
begin
  result := string( PAnsiChar( SDL_GetBasePath ) )
end;

// free resources, prints the last SDL error message,
// then after 2 seconds halts the program execution
procedure Tsdl.errorFatal;
begin
  finalizeAll;
  print('ERROR: '+ string(SDL_GetError) );
  SDL_Delay(2000);
  Halt;
end;

// Prints an error message on console window, keep program running
procedure Tsdl.errorMsg(s:string);
begin
  print('Error: '+ s);
end;

procedure Tsdl.print(s: string);
begin
  {$IFDEF DEBUG}
    {$IFDEF CONSOLE}
    writeln(s);
    {$ENDIF}
  {$ENDIF}
end;

procedure Tsdl.Quit;
begin
  fExitMainLoop := True;
end;

procedure Tsdl.SetFont(const Value: PBitmapFont);
begin
  FFont := Value;
end;

procedure Tsdl.setFullScreen(const Value: Boolean);
begin
  fFullScreen := value;
  if value  then
    SDL_SetWindowFullscreen( fWindow, fFullScreenType)
            else
    SDL_SetWindowFullscreen( fWindow, 0);
  updateRenderSize;
end;

procedure Tsdl.setLogicalSize(const Value: TSDL_Point);
begin
  fLogicalSize := Value;
  SDL_RenderSetLogicalSize(fRend, value.x, value.y);
end;

procedure Tsdl.SetMainLoop(aMainLoop: TProc);
begin
  if Assigned(aMainLoop) then fMainLoop := aMainLoop;
end;

procedure Tsdl.SetOnDraw(AValue: TProc);
begin
  if Assigned(AValue) then fOnDraw:=AValue;
end;

procedure Tsdl.SetonFinalize(const Value: TProc);
begin
  if Assigned(Value) then fOnFinalize := Value;
end;

procedure Tsdl.SetonLoad(AValue: TProc);
begin
  if Assigned(AValue) then fOnLoad:=AValue;
end;

procedure Tsdl.SetonUpdate(AValue: TProc);
begin
  if Assigned(AValue) then FonUpdate:=AValue;
end;

procedure Tsdl.showDriversInfo;
var
  numDrivers, i :integer;
  info :TSDL_RendererInfo;
begin
  numDrivers := SDL_GetNumRenderDrivers;
  for i := 0 to numDrivers-1 do
  begin
    SDL_GetRenderDriverInfo(i, @info);
    print( IntToStr(i)+' - '+ string(info.name));
  end;
end;

function Tsdl.textSize(s: string): TSDL_Point;
var
  i :integer;
  b :byte;
  srcRect :PSDL_Rect;
begin
  Result.x := 0; //width
  Result.y := fFont.maxH; //height
  for i:=1 to length(s) do
  begin
    b := ord( s[i] );
    srcRect := @fFont.asciiSprites[b];
    Result.x := Result.x + srcRect.w;
  end;
end;

procedure Tsdl.updateRenderSize;
begin
  SDL_GetRendererOutputSize(fRend, @fPixelWidth, @fPixelHeight);
end;

procedure Tsdl.setCenterToMiddle(var aSprite: TSprite);
begin
  aSprite.center.x := aSprite.dstRect.w div 2;
  aSprite.center.y := aSprite.dstRect.h div 2;
end;

procedure Tsdl.setColor(const sdlColor: TSDL_Color);
begin
  SDL_SetRenderDrawColor(fRend, sdlColor.r, sdlColor.g, sdlColor.b, sdlColor.a);
end;

procedure Tsdl.setFixedFPS(targetFPS: integer);
begin
  fFixedFPS := targetFPS;
  if targetFPS > 0 then fFixedFrameTime := (1000 div fFixedFPS)-1 else fFixedFrameTime := 0
end;

procedure Tsdl.setColor(r, g, b: UInt8; a: UInt8);
begin
  SDL_SetRenderDrawColor(fRend, r, g, b, a);
end;


procedure Tsdl.drawFrameProfiler;
var
  xpos, ypos :integer;
  r   :TSDL_Rect;
begin
  xpos := fPixelWidth-200;
  ypos := 0;
  if updateTime > fUpdateProfMax then fUpdateProfMax := updatetime else dec(fUpdateProfMax);
  if drawTime > fDrawProfMax then fDrawProfMax := drawTime else dec(fUpdateProfMax);
  sdl.drawText('update '+IntToStr(updateTime)+'ms', xpos,ypos, $40ffff);
  r.x := xpos + 90;  r.y := ypos + 3;
  r.h := 10;
  r.w := fUpdateProfMax;
  sdl.setColor(255,255,$40);
  SDL_RenderFillRect(sdl.rend, @r);
  ypos := ypos + 20;
  sdl.drawText('draw '+IntToStr(drawTime)+'ms', xpos, ypos);
  r.x := xpos + 90;  r.y := ypos + 3;
  r.h := 10;
  r.w := fDrawProfMax;
  sdl.setColor(255,255,255);
  SDL_RenderFillRect(sdl.rend, @r);

end;

procedure Tsdl.drawRect(x, y, w, h: SInt32; fill:boolean = false );
begin
  fTempRect.x := x;
  fTempRect.y := y;
  fTempRect.w := w;
  fTempRect.h := h;
  if fill then SDL_RenderFillRect(fRend, @fTempRect) else   SDL_RenderDrawRect(fRend, @fTempRect);;
end;

procedure Tsdl.drawSprite(var sprite: TSprite; ax, ay: integer; angle: single);
begin
  with sprite do
  begin
    //TODO use the pivot here
    dstRect.x := ax - center.x;
    dstRect.y := ay - center.y;
    {$IFDEF DEBUG}
    if SDL_RenderCopyEx(fRend, srcTex, srcRectPtr, @dstRect, angle, @sprite.center, SDL_FLIP_NONE )<>0
     then ErrorMsg(string(SDL_GetError));
    {$ELSE}
    SDL_RenderCopyEx(fRend, srcTex, srcRectPtr, @dstRect, angle, @sprite.center, SDL_FLIP_NONE )
    {$ENDIF}
  end;
end;


function Tsdl.drawText(s: string; x, y: integer; color: cardinal;  alpha: byte): TSDL_Rect;
var
  i :integer;
  b :byte;
  srcRect :PSDL_Rect;
  dstRect :TSDL_Rect;
  sc : PSDL_Color;
begin
  sc := @color;
  SDL_SetTextureColorMod(fFont.srcTex, sc.r, sc.g, sc.b);
  SDL_SetTextureAlphaMod(fFont.srcTex, alpha);
  dstRect := sdl.Rect(x,y, fFont.maxW, fFont.maxH);
  for i:=1 to length(s) do
  begin
    b := ord( s[i] );
    srcRect := @fFont.asciiSprites[b];
    dstRect.w := srcRect.w;
    dstRect.h := srcRect.h;
    SDL_RenderCopy(fRend, fFont.srcTex, srcRect, @dstRect);
    dstRect.x := dstRect.x + dstRect.w;
  end;
  result.x := x;
  result.y := y;
  result.h := fFont.maxH;
  result.w := dstRect.x - x;
end;

procedure Tsdl.drawSprite(var sprite:TSprite; ax, ay: integer  );
begin
  with sprite do
  begin
    dstRect.x := ax - center.x;;
    dstRect.y := ay - center.x;;
    {$IFDEF DEBUG}
    if SDL_RenderCopy(fRend, srcTex, srcRectPtr, @dstRect)<>0 then ErrorMsg(string(SDL_GetError));
    {$ELSE}
    SDL_RenderCopy(fRend, srcTex, srcRectPtr, @dstRect);
    {$ENDIF}
  end;
end;

function Tsdl.loadTexture(filename: string): PSDL_Texture;
begin
  //TODO: Check if the texture is already loaded, reuse pointer.
  Result := IMG_LoadTexture(fRend, PAnsiChar(AnsiString( fBasePath + filename )));
  if Result<>nil then
  begin
    fTextures.add(Result);
  end else errorMsg('Problem loading texture: '+ fBasePath + filename);
end;

function Tsdl.loadTexture(filename: string; out w, h: LongInt): PSDL_Texture;
begin
  Result := loadTexture(filename); //IMG_LoadTexture(fRend, PAnsiChar(AnsiString(filename)) );
  if Result<>nil then
  begin
    fTextures.add(Result);
    SDL_QueryTexture(Result, nil, nil, @w, @h);
  end;
end;

function Tsdl.newSprite(srcTex: PSDL_Texture; x, y, w, h: SInt32): TSprite;
var
  r :TSDL_Rect;
begin
  r := Rect(x,y,w,h);
  result := newSprite(srcTex, @r);
end;



function Tsdl.OpenFont(fileName: string; psize: integer): PTTF_Font;
var
  newpath :string;
begin
  result := TTF_OpenFont(toAnsi(fBasePath + fileName), psize);
  if result = nil then
  begin
    newpath := GetEnvironmentVariable('WINDIR');
    result := TTF_OpenFont(toAnsi(newpath +'\fonts\'+fileName), psize);
    if result=nil then
    begin
      //lets try just Arial, then
      result := TTF_OpenFont(toAnsi(newpath +'\fonts\arial.ttf'), psize);
    end;
  end;
end;

function Tsdl.newSprite(srcTex: PSDL_Texture; srcRectPtr: PSDL_Rect): TSprite;
begin
  result := Default(TSprite);
  result.srcTex := srcTex;
  if srcRectPtr = nil then
  begin
    //get the whole texture we need the dimensions
    SDL_QueryTexture(srcTex, nil, nil, @result.dstRect.w, @result.dstRect.h);
    result.srcRect.w := result.dstRect.w;
    result.srcRect.h := result.dstRect.h;
  end else
  begin
    result.srcRect := srcRectPtr^;
    result.srcRectPtr := @result.srcRect
  end;
  //result.center.x := result.dstRect.w div 2;
  //result.center.y := result.dstRect.h div 2;
end;

function Tsdl.Rect(ax, ay, aw, ah: integer): TSDL_Rect;
begin
  with result do
  begin
    x := ax;
    y := ay;
    w := aw;
    h := ah;
  end;
end;


initialization
  sdl := Tsdl.create;
  with sdl.cfg do
  begin
    window.title := 'SDL2-Delphi Application';
    window.w :=640;
    window.h :=480;
    window.flags := 0;
    window.fullScreenType :=  SDL_WINDOW_FULLSCREEN_DESKTOP;
    window.fullScreen := false;
    subsystems := SDL_INIT_VIDEO or SDL_INIT_AUDIO or SDL_INIT_TIMER or SDL_INIT_EVENTS ;
    RenderDriverIndex := -1;
    RenderFlags := 0;
    imgFlags := IMG_INIT_PNG;
    defaultFont := 'vera.ttf';
    defaultFontSize := 12;
    basePath := '';
    savePath_org := 'myCompany';
    savePath_app := 'myApp';
  end;
finalization
  sdl.free;
end.

