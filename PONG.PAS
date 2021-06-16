program pong;
uses dos,teclas,imagen,pcx;

const
  MaxX=319;
  MaxY=199;
  Aceleracion=15;
  MaxEstela=15;

type
  tPala=record
    x:integer;
    y:integer;
    acel:integer; {tpo moviendose}
    vel:byte;
    puntos:integer;
    iPala:array[0..2] of tImagen;
    {Especiales: al coger iconos del centro}
    MaxVel:byte;  {Maxima velocidad acelera: 1=Normal,2-3=Especial}
    VelBola:byte; {1=Normal,2-3=Velocidad manda la bola}
    Tipo:byte;    {0=Normal,1=mediana,2=grande}
    pant:byte;    {0=Nomal(sin),1-2=Pantalla salva un/dos gol}
    {Directos: golpes especiales con izquierda-derecha/arr/aba}
    Dir:boolean;
    DirTpo:integer;  {tpo dura directo}
    DirToca:boolean; {toca bola durante directo}
    DirAct:boolean;  {despues se pulsa tecla direccion hasta dispara}
    DirArr:boolean;  {tecla direccion}
    DirHor:boolean;  {tecla direccion}
    DirAba:boolean;  {tecla direccion}
    end;
  tEstela=record
    x:integer;
    y:integer;
    end;
  tBola=record
    x:integer;
    y:integer;
    vel:byte;
    dir:byte;  {0=Quieta,1=Der,2=Izq}
    incX:Shortint; {incremento horizontal}
    incY:Shortint; {incremento vertical}
    cX:byte;   {cont horiz}
    cY:byte;   {cont vert}
    iBola:tImagen;
    {estela}
    Estela:boolean;
    Est:array[0..MaxEstela] of tEstela; {Posic bola en la estela}
    iEst:array[0..2] of tImagen;
    end;
  tEsp=record {Diamantes del centro}
    x:integer;
    y:integer;
    Existe:boolean;
    Tipo:byte; {0=MaxVel,1=VelBola,2=Tama¤o,3=Pantalla}
    Donde:byte; {0=Centro,izq,der; 1=Centro,izq; 2=Centro,der}
    iEsp:array[0..3] of tImagen;
    end;
  tTeclas=record
    Der,Izq,Arr,Aba:byte;
    end;
  tTeclasMov=record
    Arr:boolean;
    Aba:boolean;
    Izq:boolean;
    Der:boolean;
    end;
  tOpc=record {Opciones del juego}
    Jugadores:byte; {1->Jug1&Comp,2->Jug2&Jug1,3->Comp&Jug1}
    {Hacer DOBLES}
    Pausa:longint;  {Velocidad del juego}
    Tcl:tTeclas;    {Jugador1}
    Tcl2:tTeclas;   {Jugador2}
    kP:boolean;     {tecla P pulsada}
    end;

var
  Pala,Pala2:tPala;
  Bola:tBola;
  Esp:tEsp;
  Opc:tOpc;
  wPant,wFondo:word;
  i,Cursor,Error:integer;
  Frames,FramesSeg,Tiempo:real;




procedure PausaPong(Tpo:longint);
var
  r:real;
  i,l:longint;
begin
  for i:=0 to Opc.Pausa do
    for l:=0 to Tpo do
      r:=2357018.04569 / 57399.628809;
end;



procedure IniciaTpo;
var
  h,m,s,s100:word;
begin
  GetTime(h,m,s,s100);
  Tiempo:=h*3600+m*60+s+s100/100;
end;



function TpoPasado:real;
var
  h,m,s,s100:word;
  tpo:real;
begin
  tpo:=Tiempo;
  GetTime(h,m,s,s100);
  Tiempo:=h*3600+m*60+s+s100/100;
  TpoPasado:=Tiempo-Tpo;
end;



procedure MoverBola(var Bol:tBola; var iBol:tImagen);
var
  veloc:integer;
begin
  {
  dir=1 -> der, dir=2 -> izq

  incX=2,incY=1  -> der,der y aba
  incX=3,incY=-1 -> der,der,der y arr
  incX=1,incY=2  -> arr,arr y der
  incX=1,incY=-3 -> aba,aba,aba y der
  incX=1,incY=0  -> der

  incX=-2,incY=1  -> izq,izq y aba
  incX=-3,incY=-1 -> izq,izq,der y arr
  incX=-1,incY=2  -> arr,arr y izq
  incX=-1,incY=-3 -> aba,aba,aba y izq
  incX=-1,incY=0  -> izq
  }

  with Bol do
    begin
      if Bol.Estela then
        Veloc:=vel*2
      else
        Veloc:=vel;

      if dir<>0 then
        begin
          if (abs(incX)>0) and (abs(incX)>=abs(incY)) then {mas hor que ver}
            begin
              cX:=cX+1;
              if cX>=abs(incX) then
                begin
                  cX:=0;
                  y:=y+incY*veloc;
                  if (y<0) or (y+iBol.TamanoY>MaxY) then
                    incY:=-incY;
                end;
              if incX>=0 then
                x:=x+veloc
              else
                x:=x-veloc;
            end;

          if (abs(incY)>0) and (abs(incX)<abs(incY)) then {mas ver que hor}
            begin
              cY:=cY+1;
              if cY>=abs(incY) then
                begin
                  cY:=0;
                  x:=x+incX*veloc;
                end;
              if incY>=0 then
                y:=y+veloc
              else
                y:=y-veloc;
              if (y<0) or (y+iBol.TamanoY>MaxY) then
                incY:=-incY;
            end;

        end;

      if y<0 then
        y:=0;
      if y+iBol.TamanoY>MaxY then
        y:=MaxY-iBol.TamanoY;

      if (x<0) and (Pala.Pant>0) then
        begin
          Pala.Pant:=Pala.Pant-1;
          x:=0;
          incX:=-incX;
        end;
      if (x+iBol.TamanoX>MaxX) and (Pala2.Pant>0) then
        begin
          Pala2.Pant:=Pala2.Pant-1;
          x:=MaxX-iBol.TamanoX;
          incX:=-incX;
        end;
    end;
end;



procedure Presentacion;
type
  pChar=array[char] of array[0..15] of byte;
var
  p:^pChar;
  Car:char;
  i,j,b:integer;
  iCar,iCarIni:integer;
  iX,iY:integer;
  x,y:integer;
  regs:registers;
  sTexto:string;
  col:integer;
  Tx,Ty:integer;
  iPres:array [0..7] of tImagen; {cuadrados de colores}

begin
  sTexto:='     PONG    Chou 2000';

  for i:=0 to 7 do
    LoadImagenPcxXY('esp.pcx','',i*11,47,i*11+10,57,iPres[i],Error);

  Tx:=iPres[0].TamanoX-1;
  Ty:=iPres[0].TamanoY-1;

  regs.ax:=$1130;
  regs.bh:=6;
  intr($10,regs);
  p:=ptr(regs.es,regs.bp);

  PausaPong(500);
  ClsWhere(0,wPant);
  repeat
  until not TeclaPulsada;

  iY:=25;
  iX:=0;
  iCarIni:=0;
  Col:=0;
  repeat
    x:=-iX*Tx;
    iCar:=iCarIni;
    while iCar<=iCarIni+5 do {+7}
      begin
        Car:=sTexto[iCar mod length(sTexto)+1];
        j:=0;
        while j<=15 do
          begin
            b:=p^[car][j];
            i:=7;
            while i>=0 do
              begin
                if odd(b) and (x+i*Tx>=0) and (x+i*Tx<=319-Tx)
                then
                  begin
                    PutImagenXYSinWhere320(x+i*Tx,iY+j*Ty,iPres[Col],255,wPant);
                  end;
                b:=b shr 1;
                dec(i);
              end;
            inc(j);
          end;
        inc(x,8*Tx);
        inc(iCar);
      end;

    flip(wPant,SegA000);
    ClsWhere(0,wPant);
    PausaPong(2500);

    inc(Col);
    if Col>7 then Col:=0;

    inc(iX);
    if iX>7
    then
      begin
        iX:=0;
        inc(iCarIni);
        if iCarIni>=length(sTexto)
        then iCarIni:=0;
      end;
  until TeclaPulsada;

end;



procedure Presentacion2;
const
  Num=15;
var
  B:array[0..Num] of tBola;
  Img:tImagen;
  i:integer;
begin
  {Img:=iPresent;}
  Img:=Bola.iBola;

  {CreaBolas}
  for i:=0 to Num do
    with B[i] do
    begin
      case i of
        0:begin
            incX:=0;
            incY:=-1;
          end;
        1:begin
            incX:=1;
            incY:=-2;
          end;
        2:begin
            incX:=1;
            incY:=-1;
          end;
        3:begin
            incX:=2;
            incY:=-1;
          end;
        4:begin
            incX:=1;
            incY:=0;
          end;
        5:begin
            incX:=2;
            incY:=1;
          end;
        6:begin
            incX:=1;
            incY:=1;
          end;
        7:begin
            incX:=1;
            incY:=2;
          end;
        8:begin
            incX:=0;
            incY:=1;
          end;
        9:begin
            incX:=-1;
            incY:=2;
          end;
        10:begin
             incX:=-1;
             incY:=1;
           end;
        11:begin
             incX:=-2;
             incY:=1;
           end;
        12:begin
             incX:=-1;
             incY:=0;
           end;
        13:begin
             incX:=-2;
             incY:=-1;
           end;
        14:begin
             incX:=-1;
             incY:=-1;
           end;
        15:begin
             incX:=-1;
             incY:=-2;
           end;
      end;
      Vel:=1;
      Dir:=5;
      cX:=0;
      cY:=0;
      Estela:=false;
      x:=MaxX div 2-Img.TamanoX div 2;
      y:=MaxY div 2-Img.TamanoY div 2;
    end;

  repeat
  until not TeclaPulsada;

  repeat
    ClsWhere(0,wPant);
    for i:=0 to Num do
      begin
        Pala.Pant:=2; {pa que reboten}
        Pala2.Pant:=2;

        MoverBola(B[i],Bola.iBola);
        PutImagenXYSinWhere320(B[i].x,B[i].y,Img,255,wPant);
      end;
    flip(wPant,SegA000);

    PausaPong(150);
  until TeclaPulsada;
end;



procedure Presentacion4;
const
  Num=47;
var
  B:array[0..Num] of tBola;
  Img:array[0..2] of tImagen;
  i:integer;
begin

  LoadImagenPcxXY('bola.pcx','',14,0,20,6,Img[0],Error); {azul}
  LoadImagenPcxXY('bola.pcx','',7,0,13,6,Img[1],Error);  {rojo}
  Img[2]:=Bola.iBola; {amar}

  {CreaBolas}
  for i:=0 to Num do
    with B[i] do
    begin
      case i div 3 of
        0:begin
            incX:=0;
            incY:=-1;
          end;
        1:begin
            incX:=1;
            incY:=-2;
          end;
        2:begin
            incX:=1;
            incY:=-1;
          end;
        3:begin
            incX:=2;
            incY:=-1;
          end;
        4:begin
            incX:=1;
            incY:=0;
          end;
        5:begin
            incX:=2;
            incY:=1;
          end;
        6:begin
            incX:=1;
            incY:=1;
          end;
        7:begin
            incX:=1;
            incY:=2;
          end;
        8:begin
            incX:=0;
            incY:=1;
          end;
        9:begin
            incX:=-1;
            incY:=2;
          end;
        10:begin
             incX:=-1;
             incY:=1;
           end;
        11:begin
             incX:=-2;
             incY:=1;
           end;
        12:begin
             incX:=-1;
             incY:=0;
           end;
        13:begin
             incX:=-2;
             incY:=-1;
           end;
        14:begin
             incX:=-1;
             incY:=-1;
           end;
        15:begin
             incX:=-1;
             incY:=-2;
           end;
      end;
      if i mod 3=0 then
        Vel:=1
      else
        if i mod 3=1 then
          Vel:=2
        else
          Vel:=3;

      Dir:=5;
      cX:=0;
      cY:=0;
      Estela:=false;
      x:=MaxX div 2-Img[0].TamanoX div 2;
      y:=MaxY div 2-Img[0].TamanoY div 2;
    end;

  repeat
  until not TeclaPulsada;

  repeat
    ClsWhere(0,wPant);
    for i:=0 to Num do
      begin
        Pala.Pant:=2; {pa que reboten}
        Pala2.Pant:=2;

        MoverBola(B[i],Bola.iBola);

        if i mod 3=0 then
          PutImagenXYSinWhere320(B[i].x,B[i].y,Img[0],255,wPant)
        else
          if i mod 3=1 then
            PutImagenXYSinWhere320(B[i].x,B[i].y,Img[1],255,wPant)
          else
            PutImagenXYSinWhere320(B[i].x,B[i].y,Img[2],255,wPant);
      end;
    flip(wPant,SegA000);

    PausaPong(400);
  until TeclaPulsada;
end;



procedure Presentacion3;
var
  B:array[0..300] of tBola;
  Num:integer;
  i,j:integer;
  Img:tImagen;
begin
  LoadImagenPcxXY('esp.pcx','',0,36,10,46,Img,Error); {Bola naranja}

  Num:=random(100)+200;

  {CreaBolas}
  for i:=0 to Num do
    with B[i] do
    begin
      j:=random(16);
      case j of
        0:begin
            incX:=0;
            incY:=-1;
          end;
        1:begin
            incX:=1;
            incY:=-2;
          end;
        2:begin
            incX:=1;
            incY:=-1;
          end;
        3:begin
            incX:=2;
            incY:=-1;
          end;
        4:begin
            incX:=1;
            incY:=0;
          end;
        5:begin
            incX:=2;
            incY:=1;
          end;
        6:begin
            incX:=1;
            incY:=1;
          end;
        7:begin
            incX:=1;
            incY:=2;
          end;
        8:begin
            incX:=0;
            incY:=1;
          end;
        9:begin
            incX:=-1;
            incY:=2;
          end;
        10:begin
             incX:=-1;
             incY:=1;
           end;
        11:begin
             incX:=-2;
             incY:=1;
           end;
        12:begin
             incX:=-1;
             incY:=0;
           end;
        13:begin
             incX:=-2;
             incY:=-1;
           end;
        14:begin
             incX:=-1;
             incY:=-1;
           end;
        15:begin
             incX:=-1;
             incY:=-2;
           end;
      end;
      Vel:=random(3)+1;
      Dir:=5;
      cX:=0;
      cY:=0;
      Estela:=false;
      x:=random(MaxX-Img.TamanoX);
      y:=random(MaxY-Img.TamanoY);
    end;

  repeat
  until not TeclaPulsada;

  repeat
    ClsWhere(0,wPant);
    for i:=0 to Num do
      begin
        Pala.Pant:=2; {pa que reboten}
        Pala2.Pant:=2;

        MoverBola(B[i],Bola.iBola);
        PutImagenXYSinWhere320(B[i].x,B[i].y,Img,255,wPant);
      end;
    flip(wPant,SegA000);

    PausaPong(50);
  until TeclaPulsada;

  repeat
  until not TeclaPulsada;
end;



function Menu:integer;
var
  colorVer,colorVio:tColor8;
  i,j:integer;
  x,y:integer;
  ay:array[1..4] of integer;
  cursor:byte;
  Salir,xPos,noLeft,noRight:boolean;
  Pal:tPala;

  procedure PonMenu;
  var
    str1:string;
    y2:integer;
  begin
    ClsWhere(0,wPant);

    if Opc.Jugadores=1 then
      str1:='Jugador1 & Ordenador';
    if Opc.Jugadores=2 then
      str1:='Jugador2 & Jugador1';
    if Opc.Jugadores=3 then
      str1:='Ordenador & Jugador1';
    WriteColorWhere(70,ay[1],-1,str1,ColorVer,wPant);

    str1:='Jugar';
    WriteColorWhere(70,ay[2],-1,str1,ColorVio,wPant);

    str1:='Opciones';
    WriteColorWhere(70,ay[3],-1,str1,ColorVer,wPant);

    str1:='Salir';
    WriteColorWhere(70,ay[4],-1,str1,ColorVio,wPant);

    y2:=y;
    if y2<=ay[1]+(ay[2]-ay[1]) div 2 then
      Pal:=Pala;
    if (y2>ay[1]+(ay[2]-ay[1]) div 2) and (y2<=ay[2]+(ay[3]-ay[2]) div 2) then
      Pal:=Pala2;
    if (y2>ay[2]+(ay[3]-ay[2]) div 2) and (y2<=ay[3]+(ay[4]-ay[3]) div 2) then
      Pal:=Pala;
    if (y2>ay[3]+(ay[4]-ay[3]) div 2) then
      Pal:=Pala2;
    PutImagenXYSinWhere320(40+x,y-6,Pal.iPala[0],255,wPant);

    flip(wPant,SegA000);

    if xPos then
      begin
        x:=x+1;
        if x>10 then
          xPos:=false;
      end
    else
      begin
        x:=x-1;
        if x<0 then
          xPos:=true;
      end;
  end;

begin
  repeat
  until not TeclaPulsada;

  ay[1]:=40;
  ay[2]:=80;
  ay[3]:=120;
  ay[4]:=160;
  x:=0;
  xPos:=true; {x aumentan}
  Salir:=false;
  Cursor:=1;

  {Verde}
  for i:=160 to 160+7 do
    ColorVer[i-160]:=i;

  {Violeta}
  i:=0;
  j:=90;
  while i<8 do
    begin
      ColorVio[i]:=j;
      j:=j+2;
      i:=i+1;
    end;

  repeat
    y:=ay[Cursor];
    PonMenu;

    if KeyDown[LeftScan] then
      begin
        if noLeft then
          begin
            NoLeft:=false;
            if Cursor=1 then
              begin
                Opc.Jugadores:=Opc.Jugadores-1;
                if Opc.Jugadores<1 then
                Opc.Jugadores:=3;
              end;
          end;
        end
    else
      NoLeft:=true;

    if KeyDown[RightScan] then
    begin
      if noRight then
        begin
          NoRight:=false;
          if Cursor=1 then
            begin
              Opc.Jugadores:=Opc.Jugadores+1;
              if Opc.Jugadores>3 then
              Opc.Jugadores:=1;
            end;
        end;
      end
    else
      NoRight:=true;

    if KeyDown[UpScan] then
      begin
        y:=ay[Cursor];
        Cursor:=Cursor-1;
        if Cursor<1 then
          Cursor:=4;

        while (y<>ay[Cursor]) and not KeyDown[escScan] do
          begin
            PonMenu;

            if Cursor=4 then
              PausaPong(100)
            else
              PausaPong(200);

            y:=y-1;
            if y+Pala.iPala[0].TamanoY<0 then
              y:=MaxY;
          end;
      end;

    if KeyDown[DownScan] then
      begin
        y:=ay[Cursor];
        Cursor:=Cursor+1;
        if Cursor>4 then
          Cursor:=1;

        while (y<>ay[Cursor]) and not KeyDown[escScan] do
          begin
            PonMenu;

            if Cursor=1 then
              PausaPong(100)
            else
              PausaPong(200);

            y:=y+1;
            if y>MaxY then
              y:=-Pala.iPala[0].TamanoY;
          end;
      end;

    if KeyDown[entScan] then
      begin
        case Cursor of
          {3 opciones}
          2,4:Salir:=true;
        end;
      end;

    if KeyDown[escScan] then
      begin
        Salir:=true;
        Cursor:=4;
      end;

    PausaPong(200);

  until Salir;

  Menu:=Cursor;
end;



procedure PonTexto;
var
  str1,str2,str3,str4:string;
  color8:tColor8;
  i,j:integer;
begin
  {0=MaxVel,1=VelBola,2=Tama¤o,3=Pantalla}

  for i:=160 to 160+7 do
    Color8[i-160]:=i;

  case Pala.MaxVel of
    1:str1:=' ';
    2:str1:='v';
    3:str1:='V';
  end;
  case Pala.VelBola of
    1:str2:=' ';
    2:str2:='b';
    3:str2:='B';
  end;
  case Pala.Tipo of
    0:str3:=' ';
    1:str3:='t';
    2:str3:='T';
  end;
  case Pala.Pant of
    0:str4:=' ';
    1:str4:='p';
    2:str4:='P';
  end;
  WriteColorWhere(10,191,-1,concat(str1,str2,str3,str4),Color8,wPant);

  str1:='Puntos=';
  str(Pala.Puntos,str2);
  WriteColorWhere(60,191,-1,concat(str1,str2),Color8,wPant);


  str1:='Donde=';
  str(Esp.Donde,str2);
  WriteColorWhere(60,181,-1,concat(str1,str2),Color8,wPant);


  {
  if Bola.Estela and (Bola.Dir=1) then
    str1:='Est=T'
  else
    str1:='Est=F';
  WriteColorWhere(20,141,-1,str1,Color8,wPant);

  if Pala.Dir then
    str1:='Dir=T'
  else
    str1:='Dir=F';
  WriteColorWhere(20,151,-1,str1,Color8,wPant);

  str1:='Tpo=';
  str(Pala.DirTpo,str2);
  WriteColorWhere(20,161,-1,concat(str1,str2),Color8,wPant);

  if Pala.DirToca then
    str1:='Toca=T'
  else
    str1:='Toca=F';
  WriteColorWhere(20,171,-1,str1,Color8,wPant);

  if Pala.DirAct then
    str1:='Act=T'
  else
    str1:='Act=F';
  WriteColorWhere(20,181,-1,str1,Color8,wPant);
  }


  i:=0;
  j:=90;
  while i<8 do
    begin
      Color8[i]:=j;
      j:=j+2;
      i:=i+1;
    end;

  case Pala2.MaxVel of
    1:str1:=' ';
    2:str1:='v';
    3:str1:='V';
  end;
  case Pala2.VelBola of
    1:str2:=' ';
    2:str2:='b';
    3:str2:='B';
  end;
  case Pala2.Tipo of
    0:str3:=' ';
    1:str3:='t';
    2:str3:='T';
  end;
  case Pala2.Pant of
    0:str4:=' ';
    1:str4:='p';
    2:str4:='P';
  end;
  WriteColorWhere(170,191,-1,concat(str1,str2,str3,str4),Color8,wPant);

  str1:='Puntos=';
  str(Pala2.Puntos,str2);
  WriteColorWhere(220,191,-1,concat(str1,str2),Color8,wPant);

  {
  if Bola.Estela and (Bola.Dir=2) then
    str1:='Est=T'
  else
    str1:='Est=F';
  WriteColorWhere(220,141,-1,str1,Color8,wPant);

  if Pala2.Dir then
    str1:='Dir=T'
  else
    str1:='Dir=F';
  WriteColorWhere(220,151,-1,str1,Color8,wPant);

  str1:='Tpo=';
  str(Pala2.DirTpo,str2);
  WriteColorWhere(220,161,-1,concat(str1,str2),Color8,wPant);

  if Pala2.DirToca then
    str1:='Toca=T'
  else
    str1:='Toca=F';
  WriteColorWhere(220,171,-1,str1,Color8,wPant);

  if Pala2.DirAct then
    str1:='Act=T'
  else
    str1:='Act=F';
  WriteColorWhere(220,181,-1,str1,Color8,wPant);
  }


  for i:=118 to 118+7 do
    Color8[i-118]:=i;

  str(MemAvail,str1);
  WriteColorWhere(260,2,-1,str1,Color8,wPant);

  str(FramesSeg:0:3,str1);
  WriteColorWhere(10,2,-1,str1,Color8,wPant);
end;



procedure CambiarDonde;
var
  i:integer;
begin
  with Pala do
    begin
      i:=MaxVel-1;
      i:=i+VelBola-1;
      i:=i+tipo;
      i:=i+Pant;

      {0=Centro,izq,der; 1=Centro,izq; 2=Centro,der}
      if i>=4 then
        Esp.Donde:=2
      else
        if Esp.Donde=2 then
          Esp.Donde:=0;
    end;

  with Pala2 do
    begin
      i:=MaxVel-1;
      i:=i+VelBola-1;
      i:=i+tipo;
      i:=i+Pant;

      {0=Centro,izq,der; 1=Centro,izq; 2=Centro,der}
      if i>=4 then
        Esp.Donde:=1
      else
        if Esp.Donde=1 then
          Esp.Donde:=0;
    end;
end;



procedure IniciaJuego(saca:integer);
begin
  Esp.Existe:=false;

  if saca=1 then
    begin
      Bola.x:=50;
      Bola.y:=100-Bola.iBola.TamanoY div 2;

      {Pierde especiales}
      Pala.MaxVel:=1;
      Pala.VelBola:=1;
      Pala.tipo:=0;
      Pala.Pant:=0;
    end;
  if saca=2 then
    begin
      Bola.x:=MaxX-50-Bola.iBola.TamanoX;
      Bola.y:=100-Bola.iBola.TamanoY div 2;

      Pala2.MaxVel:=1;
      Pala2.VelBola:=1;
      Pala2.tipo:=0;
      Pala2.Pant:=0;
    end;

  CambiarDonde;

  Bola.Vel:=1;
  Bola.Estela:=false;

  Pala.x:=10;
  Pala.y:=100-Pala.iPala[Pala.Tipo].TamanoY div 2;
  Pala.Acel:=0;
  Pala.Vel:=1;
  Pala.Dir:=false;

  Pala2.x:=309-Pala2.iPala[Pala2.Tipo].TamanoX;
  Pala2.y:=100-Pala2.iPala[Pala2.Tipo].TamanoY div 2;
  Pala2.Acel:=0;
  Pala2.Vel:=1;
  Pala2.Dir:=false;
end;



procedure RandomBola(triple:boolean);
var
  r:integer;
begin
  if triple then
    begin
      Bola.dir:=0;
    end
  else
    begin
      r:=random(2);

      case r of
        0:begin
            Bola.incX:=1;
            Bola.incY:=-2;
          end;
        1:begin
            Bola.incX:=1;
            Bola.incY:=2;
          end;
      end;
    end;
end;



procedure GolpeDir(Pal,Tcl:integer);

  procedure GD(var Pala:tPala);
  var
    i:integer;
  begin
    with pala do
      if DirAct then
        begin
          if Tcl=1 then
            DirArr:=true;
          if Tcl=2 then
            DirHor:=true;
          if Tcl=3 then
            DirAba:=true;

          if DirTpo>10 then
            begin
              Bola.Estela:=true;
              for i:=0 to MaxEstela do
                begin
                  Bola.Est[i].x:=Bola.x;
                  Bola.Est[i].y:=Bola.y;
                end;

              if DirHor then
                if DirArr then
                  if DirAba then
                    RandomBola(true) {Escoge dir aleat, que se divida en 3, 1 verd}
                  else
                    begin
                      Bola.incX:=2;
                      Bola.incY:=-1;
                    end
                else
                  if DirAba then
                    begin
                      Bola.incX:=2;
                      Bola.incY:=1;
                    end
                  else
                    begin
                      Bola.incX:=1;
                      Bola.incY:=0;
                    end
              else
                if DirArr then
                  if DirAba then
                    RandomBola(false) {Escoge dir aleat aarrib o abaj}
                  else
                    begin
                      Bola.incX:=1;
                      Bola.incY:=-1;
                    end
                else
                  if DirAba then
                    begin
                      Bola.incX:=1;
                      Bola.incY:=1;
                    end
                  else
                    begin
                      Bola.incX:=0;
                      Bola.incY:=0;
                    end;

              if Bola.Dir=2 then
                Bola.incX:=-Bola.incX;

              Dir:=false;
              DirAct:=false;
              DirTpo:=0;
              DirToca:=false;
              DirArr:=false;
              DirHor:=false;
              DirAba:=false;
            end;
        end
      else
        if (DirTpo<50) and DirToca then
          begin
            DirAct:=true;
            DirTpo:=0;
            DirToca:=false;

            if Tcl=1 then
              DirArr:=true;
            if Tcl=2 then
              DirHor:=true;
            if Tcl=3 then
              DirAba:=true;
          end
        else
          begin
            Dir:=false;
            DirTpo:=0;
            DirToca:=false;
          end;
  end;

begin
  if Pal=1 then
    GD(Pala);
  if Pal=2 then
    GD(Pala2);
end;



procedure TocarBola;
var
  by:integer;
begin
  {if (Bola.dir=0) or (Bola.dir=2) then {quieta,izq}
    if (Pala.x<=Bola.x+Bola.iBola.TamanoX) and (Pala.x+Pala.iPala[Pala.Tipo].TamanoX>=Bola.x) and
       (Pala.y<=Bola.y+Bola.iBola.TamanoY) and (Pala.y+Pala.iPala[Pala.Tipo].TamanoY>=Bola.y)
    then
      begin
        if Bola.Estela and (Bola.dir=2) then
          Bola.Estela:=false;

        if Pala.Dir then
          Pala.DirToca:=true;

        by:=Bola.y+Bola.iBola.TamanoY div 2-Pala.y;

        case Pala.Tipo of
          0:begin {arriba, 0-3, 4-7, 8-11, 12-15, 16-19, abajo}
              if by<0 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=3) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-1;
                end;
              if (by>=4) and (by<=7) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=-1;
                end;
              if (by>=8) and (by<=11) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=0;
                end;
              if (by>=12) and (by<=15) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=1;
                end;
              if (by>=16) and (by<=19) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=1;
                end;
              if by>19 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=2;
                end;
            end;
          1:begin {arriba, 0-5, 6-11, 12-17, 18-23, 24-29, abajo}
              if by<0 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=5) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-1;
                end;
              if (by>=6) and (by<=11) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=-1;
                end;
              if (by>=12) and (by<=17) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=0;
                end;
              if (by>=18) and (by<=23) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=1;
                end;
              if (by>=24) and (by<=29) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=1;
                end;
              if by>29 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=2;
                end;
            end;
          2:begin {arriba, 0-7, 8-15, 16-23, 24-31, 32-39, abajo}
              if by<0 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=7) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=-1;
                end;
              if (by>=8) and (by<=15) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=-1;
                end;
              if (by>=16) and (by<=23) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=0;
                end;
              if (by>=24) and (by<=31) then
                begin
                  Bola.incX:=2;
                  Bola.incY:=1;
                end;
              if (by>=32) and (by<=39) then
                begin
                  Bola.incX:=1;
                  Bola.incY:=1;
                end;
              if by>39 then
                begin
                  Bola.incX:=1;
                  Bola.incY:=2;
                end;
            end;
        end;

        Bola.dir:=1; {der}
        Bola.Vel:=Pala.VelBola;
      end;

  {if (Bola.dir=0) or (Bola.dir=1) then {quieta,der}
    if (Pala2.x<=Bola.x+Bola.iBola.TamanoX) and (Pala2.x+Pala2.iPala[Pala2.Tipo].TamanoX>=Bola.x) and
       (Pala2.y<=Bola.y+Bola.iBola.TamanoY) and (Pala2.y+Pala2.iPala[Pala2.Tipo].TamanoY>=Bola.y)
    then
      begin
        if Bola.Estela and (Bola.dir=1) then
          Bola.Estela:=false;

        if Pala2.Dir then
          Pala2.DirToca:=true;

        by:=Bola.y+Bola.iBola.TamanoY div 2-Pala2.y;

        case Pala2.Tipo of
          0:begin {arriba, 0-3, 4-7, 8-11, 12-15, 16-19, abajo}
              if by<0 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=3) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-1;
                end;
              if (by>=4) and (by<=7) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=-1;
                end;
              if (by>=8) and (by<=11) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=0;
                end;
              if (by>=12) and (by<=15) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=1;
                end;
              if (by>=16) and (by<=19) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=1;
                end;
              if by>19 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=2;
                end;
            end;
          1:begin {arriba, 0-5, 6-11, 12-17, 18-23, 24-29, abajo}
              if by<0 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=5) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-1;
                end;
              if (by>=6) and (by<=11) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=-1;
                end;
              if (by>=12) and (by<=17) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=0;
                end;
              if (by>=18) and (by<=23) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=1;
                end;
              if (by>=24) and (by<=29) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=1;
                end;
              if by>29 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=2;
                end;
            end;
          2:begin {arriba, 0-7, 8-15, 16-23, 24-31, 32-39, abajo}
              if by<0 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-2;
                end;
              if (by>=0) and (by<=7) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=-1;
                end;
              if (by>=8) and (by<=15) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=-1;
                end;
              if (by>=16) and (by<=23) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=0;
                end;
              if (by>=24) and (by<=31) then
                begin
                  Bola.incX:=-2;
                  Bola.incY:=1;
                end;
              if (by>=32) and (by<=39) then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=1;
                end;
              if by>39 then
                begin
                  Bola.incX:=-1;
                  Bola.incY:=2;
                end;
            end;
        end;

        Bola.dir:=2; {izq}
        Bola.Vel:=Pala2.VelBola;
      end;
end;



procedure GolBola(var Espec:longint);
begin
  if (Bola.x>MaxX) then
    begin
      Pala.Puntos:=Pala.Puntos+1;
      IniciaJuego(2);
      Espec:=0;
      Bola.dir:=0;
      PausaPong(10000);
    end;

  if (Bola.x+Bola.iBola.TamanoX<0) then
    begin
      Pala2.Puntos:=Pala2.Puntos+1;
      IniciaJuego(1);
      Espec:=0;
      Bola.dir:=0;
      PausaPong(10000);
    end;
end;



procedure PonEspecial(var Espec:longint);
var
  r:integer;
  continuar:boolean;
begin
  Espec:=0;

  Esp.Existe:=true;
  Esp.tipo:=random(4);

  case Esp.Donde of
    0: begin
         r:=random(4);
         if r<2 then
           Esp.x:=153;
         if r=2 then
           Esp.x:=1;
         if r=3 then
           Esp.x:=MaxX-Esp.iEsp[0].TamanoX;
       end;
    1: begin {centro,izq}
         r:=random(3);
         if r=0 then
           Esp.x:=153
         else
           Esp.x:=1;
       end;
    2: begin {centro,der}
         r:=random(3);
         if r=0 then
           Esp.x:=153
         else
           Esp.x:=MaxX-Esp.iEsp[0].TamanoX;
       end;
  end;

  repeat
    Esp.y:=random(MaxY-Esp.iEsp[0].TamanoY);

    continuar:=true;
    if (Pala2.x<=Esp.x+Esp.iEsp[0].TamanoX) and (Pala2.x+Pala2.iPala[Pala2.Tipo].TamanoX>=Esp.x) and
       (Pala2.y<=Esp.y+Esp.iEsp[0].TamanoY) and (Pala2.y+Pala2.iPala[Pala2.Tipo].TamanoY>=Esp.y)
    then
      continuar:=false;
    if (Pala.x<=Esp.x+Esp.iEsp[0].TamanoX) and (Pala.x+Pala.iPala[Pala.Tipo].TamanoX>=Esp.x) and
       (Pala.y<=Esp.y+Esp.iEsp[0].TamanoY) and (Pala.y+Pala.iPala[Pala.Tipo].TamanoY>=Esp.y)
    then
      continuar:=false;
  until continuar;
end;



procedure PonerDentro(NumPala,Ant,Tipo:integer);
begin
  if NumPala=1 then
    with Pala do
      begin
        y:=y-5;
        if y<1 then y:=1;
        if y+iPala[Tipo].TamanoY>MaxY then
          y:=MaxY-iPala[Tipo].TamanoY;
        if x+iPala[Tipo].TamanoX>159 then
          x:=159-iPala[Tipo].TamanoX;
      end;
  if NumPala=2 then
    with Pala2 do
      begin
        y:=y-5;
        if y<1 then y:=1;
        if y+iPala[Tipo].TamanoY>MaxY then
          y:=MaxY-iPala[Tipo].TamanoY;
        if x+iPala[Tipo].TamanoX>MaxX then
          x:=MaxX-iPala[Tipo].TamanoX;
      end;
end;



procedure CogerEspecial;
var
  ant:integer;
begin
  {0=MaxVel,1=VelBola,2=Tama¤o,3=Pantalla}

  if (Pala.x<=Esp.x+Esp.iEsp[0].TamanoX) and (Pala.x+Pala.iPala[Pala.Tipo].TamanoX>=Esp.x) and
     (Pala.y<=Esp.y+Esp.iEsp[0].TamanoY) and (Pala.y+Pala.iPala[Pala.Tipo].TamanoY>=Esp.y)
  then
    begin
      Esp.Existe:=false;
      with Pala do
        case Esp.tipo of
          0:begin
              MaxVel:=MaxVel+1;
              if MaxVel>3 then MaxVel:=3;
            end;
          1:begin
              VelBola:=VelBola+1;
              if VelBola>3 then VelBola:=3;
            end;
          2:begin
              ant:=Tipo;
              Tipo:=Tipo+1;
              if Tipo>2 then Tipo:=2;

              if ant<>Tipo then
                PonerDentro(1,ant,Tipo); {Coloca Palas dentro campo}
            end;
          3:begin
              Pant:=Pant+1;
              if Pant>2 then Pant:=2;
            end;
        end;
    end
  else
    if (Pala2.x<=Esp.x+Esp.iEsp[0].TamanoX) and (Pala2.x+Pala2.iPala[Pala2.Tipo].TamanoX>=Esp.x) and
       (Pala2.y<=Esp.y+Esp.iEsp[0].TamanoY) and (Pala2.y+Pala2.iPala[Pala2.Tipo].TamanoY>=Esp.y)
    then
      begin
        Esp.Existe:=false;
        with Pala2 do
          case Esp.tipo of
            0:begin
                MaxVel:=MaxVel+1;
                if MaxVel>3 then MaxVel:=3;
              end;
            1:begin
                VelBola:=VelBola+1;
                if VelBola>3 then VelBola:=3;
              end;
            2:begin
                ant:=Tipo;
                Tipo:=Tipo+1;
                if Tipo>2 then Tipo:=2;
                if ant<>Tipo then
                  PonerDentro(2,ant,Tipo); {Coloca Palas dentro campo}
              end;
            3:begin
                Pant:=Pant+1;
                if Pant>2 then Pant:=2;
              end;
          end;
      end;
end;



procedure CargaPaleta;
var
  Paleta:tPaleta;
begin
  GetPalPcx('esp.pcx','',Paleta,Error);
  SetPaleta(Paleta);
end;



procedure MoverOrdenadorIzq(CampoIzq:boolean; var teclas:tTeclasMov);
{Mueve el ordenad, Si es de campo izq poner true}
var
  hy,hx:integer;
begin
  if CampoIzq then
    with Pala do
      begin
        hy:=(y+iPala[Tipo].TamanoY div 2)-(Bola.y+Bola.iBola.TamanoY div 2);

        if hy>0 then {Pala debajo bola}
          begin
            teclas.Arr:=true;
            teclas.Aba:=false;
          end;
        if hy<0 then {Pala encima bola}
          begin
            teclas.Aba:=true;
            teclas.Arr:=false;
          end;
        if hy=0 then {Pala centrada bola}
          begin
            teclas.Arr:=false;
            teclas.Aba:=false;
          end;

        {if (Bola.dir=0) and (Bola.x<159) then}
        if true then
          begin
            hx:=(x+iPala[Tipo].TamanoX-1)-Bola.x;
            if hx>0 then
              begin
                teclas.Izq:=true;
                teclas.Der:=false;
              end;
            if hx<0 then
              begin
                teclas.Der:=true;
                teclas.Izq:=false;
              end;
            if hx=0 then
              begin
                teclas.Izq:=false;
                teclas.Der:=false;
              end;
          end
        else
          if x>1 then
            begin
              teclas.Izq:=true;
              teclas.Der:=false;
            end
          else
            begin
              teclas.Izq:=false;
              teclas.Der:=false;
            end;
      end
  else
    with Pala2 do
      begin
        hy:=(y+iPala[Tipo].TamanoY div 2)-(Bola.y+Bola.iBola.TamanoY div 2);
        if hy>1 then {Pala debajo bola}
          begin
            teclas.Arr:=true;
            teclas.Aba:=false;
          end;
        if hy<1 then {Pala encima bola}
          begin
            teclas.Aba:=true;
            teclas.Arr:=false;
          end;
        if hy=0 then {Pala centrada bola}
          begin
            teclas.Arr:=false;
            teclas.Aba:=false;
          end;

        {if (Bola.dir=0) and (Bola.x>160) then}
        if true then
          begin
            hx:=x-Bola.x+Bola.iBola.TamanoX;
            if hx>0 then
              begin
                teclas.Izq:=true;
                teclas.Der:=false;
              end;
            if hx<0 then
              begin
                teclas.Der:=true;
                teclas.Izq:=false;
              end;
            if hx=0 then
              begin
                teclas.Izq:=false;
                teclas.Der:=false;
              end;
          end
        else
          if x+iPala[tipo].TamanoX<MaxX then
            begin
              teclas.Izq:=false;
              teclas.Der:=true;
            end
          else
            begin
              teclas.Izq:=false;
              teclas.Der:=false;
            end;
      end;
end;



procedure MoverJugIzq(Jug,Izq:boolean; Tcl:byte);
{Jugador humano, campo izq, teclas 1-2}
var
  teclas:tTeclas;
  Mov:tTeclasMov;
begin

  if Izq then
    with Pala do
      begin
        if Jug then
          begin
            if Tcl=1 then
              teclas:=Opc.Tcl
            else
              teclas:=Opc.Tcl2;

            if KeyDown[teclas.Arr] then
              Mov.Arr:=true
            else
              Mov.Arr:=false;
            if KeyDown[teclas.Aba] then
              Mov.Aba:=true
            else
              Mov.Aba:=false;
            if KeyDown[teclas.Izq] then
              Mov.Izq:=true
            else
              Mov.Izq:=false;
            if KeyDown[teclas.Der] then
              Mov.Der:=true
            else
              Mov.Der:=false;
          end
        else
          MoverOrdenadorIzq(true, Mov); {campo izq}


        if Mov.Arr then
          begin
            if y>1 then
              begin
                y:=y-vel;
                if y<1 then
                  y:=1;
              end;
            if Dir then
              GolpeDir(1,1);
          end;

        if Mov.Der then
          begin
            if x+iPala[Tipo].TamanoX<159 then
              begin
                x:=x+vel;
                if x+iPala[Tipo].TamanoX>159 then
                  x:=159-iPala[Tipo].TamanoX;
              end;
            if Dir then
              GolpeDir(1,2);
          end;

        if Mov.Aba then
          begin
            if y+iPala[Tipo].TamanoY<MaxY then
              begin
                y:=y+vel;
                if y+iPala[Tipo].TamanoY>MaxY then
                  y:=MaxY-iPala[Tipo].TamanoY;
              end;
            if Dir then
              GolpeDir(1,3);
          end;

        if Mov.Izq then
          begin
            if x>1 then
              begin
                x:=x-vel;
                if x<1 then
                  x:=1;
              end;
            if not Mov.Aba and not Mov.Arr and
               not Mov.Der then
              if Dir then
                begin
                  {if not DirAct then
                    DirTpo:=0;}
                end
              else
                Dir:=true;
          end;

        if not Mov.Arr and not Mov.Aba and
           not Mov.Izq and not Mov.Der then
          begin
            Acel:=0;
            Vel:=1;
          end
        else
          begin
            Acel:=Acel+1;
            if Acel>Aceleracion then
              begin
                Acel:=0;
                Vel:=Vel+1;
                if Vel>MaxVel then
                  Vel:=maxVel;
              end;
          end;

        if Dir then
          begin
            DirTpo:=DirTpo+1;
            if DirAct then
              GolpeDir(1,0)
            else
              if DirTpo>60 then
                GolpeDir(1,0)
          end;
      end


  else
    with Pala2 do
      begin
        if Jug then
          begin
            if Tcl=1 then
              teclas:=Opc.Tcl
            else
              teclas:=Opc.Tcl2;

            if KeyDown[teclas.Arr] then
              Mov.Arr:=true
            else
              Mov.Arr:=false;
            if KeyDown[teclas.Aba] then
              Mov.Aba:=true
            else
              Mov.Aba:=false;
            if KeyDown[teclas.Izq] then
              Mov.Izq:=true
            else
              Mov.Izq:=false;
            if KeyDown[teclas.Der] then
              Mov.Der:=true
            else
              Mov.Der:=false;
          end
        else
          MoverOrdenadorIzq(false, Mov); {campo der}


        if Mov.Arr then
          begin
            if y>1 then
              begin
                y:=y-vel;
                if y<1 then
                  y:=1;
              end;
            if Dir then
              GolpeDir(2,1);
          end;

        if Mov.Izq then
          begin
            if (x>161) then
              begin
                x:=x-vel;
                if x<161 then
                  x:=161;
              end;
            if Dir then
              GolpeDir(2,2);
          end;

        if Mov.Aba then
          begin
            if y+iPala[Tipo].TamanoY<MaxY then
              begin
                y:=y+vel;
                if y+iPala[Tipo].TamanoY>MaxY then
                  y:=MaxY-iPala[Tipo].TamanoY;
              end;
            if Dir then
              GolpeDir(2,3);
          end;

        if Mov.Der then
          begin
            if (x+iPala[Tipo].TamanoX<MaxX) then
              begin
                x:=x+vel;
                if x+iPala[Tipo].TamanoX>MaxX then
                  x:=MaxX-iPala[Tipo].TamanoX;
              end;
            if not Mov.Aba and not Mov.Arr and
               not Mov.Izq then
              if Dir then
                begin
                  {if not DirAct then
                    DirTpo:=0;}
                end
              else
                Dir:=true;
          end;

        if not Mov.Der and not Mov.Izq and
           not Mov.Arr and not Mov.Aba
        then
          begin
            Acel:=0;
            Vel:=1;
          end
        else
          begin
            Acel:=Acel+1;
            if Acel>Aceleracion then
              begin
                Acel:=0;
                Vel:=Vel+1;
                if Vel>MaxVel then
                  Vel:=maxVel;
              end;
            end;

        if Dir then
          begin
            DirTpo:=DirTpo+1;
            if DirAct then
              GolpeDir(2,0)
            else
              if DirTpo>60 then
                GolpeDir(2,0)
          end;
      end;
end;



procedure Jugar;
var
  i,j:integer;
  Especial:longint; {Tpo juego sin especial}

begin

  {Inicializa variables}
  Pala.Puntos:=0;
  Pala.MaxVel:=1;
  Pala.VelBola:=1;
  Pala.Pant:=0;

  Pala2.Puntos:=0;
  Pala2.MaxVel:=1;
  Pala2.VelBola:=1;
  Pala2.Pant:=0;

  Bola.vel:=1;
  Bola.dir:=0;

  IniciaJuego(random(2)+1); {saque aleatorio}
  Especial:=0;


  Frames:=0;
  IniciaTpo;


  {Empieza juego}

  repeat

    {1->Jug1&Comp,2->Jug2&Jug1,3->Comp&Jug1}

    case Opc.Jugadores of
      1:begin
          MoverJugIzq(true,true,1); {Jugador hum, Campo izq, Tcl1}
          MoverJugIzq(false,false,0); {Jugador com, Campo der, Comp}
        end;
      2:begin
          MoverJugIzq(true,true,2); {Jugador hum, Campo izq, Tcl2}
          MoverJugIzq(true,false,1); {Jugador hum, Campo der, Tcl1}
        end;
      3:begin
          MoverJugIzq(false,true,0); {Jugador com, Campo izq, comp}
          MoverJugIzq(true,false,1); {Jugador hum, Campo der, Tcl1}
        end;
    end;


    if KeyDown[ScanOf('p')] then
      begin
        if not Opc.kP then
          begin
            case Opc.Pausa of
              0: Opc.Pausa:=500;
              500: Opc.Pausa:=1000;
              1000: Opc.Pausa:=2000;
              2000: Opc.Pausa:=50000;
              else Opc.Pausa:=0;
            end;
            Opc.kP:=true;
          end;
      end
    else
      Opc.kP:=false;

    TocarBola;

    MoverBola(Bola,Bola.iBola);

    if Bola.Estela then
      begin
        for i:=MaxEstela-1 downto 0 do
          begin
            Bola.Est[i+1].x:=Bola.Est[i].x;
            Bola.Est[i+1].y:=Bola.Est[i].y;
          end;
        Bola.Est[0].x:=Bola.x;
        Bola.Est[0].y:=Bola.y;
      end;


    if not Esp.Existe then
      begin
        if Bola.Dir<>0 then
          begin
            Especial:=Especial+1;
            if Especial>400 then
              PonEspecial(Especial);
          end;
      end
    else
      CogerEspecial;


    flip(wFondo,wPant);
    PonTexto;
    PutImagenXYSinWhere320(Pala.x,Pala.y,Pala.iPala[Pala.Tipo],255,wPant);
    PutImagenXYSinWhere320(Pala2.x,Pala2.y,Pala2.iPala[Pala2.Tipo],255,wPant);
    if Esp.Existe then {Diamantes especiales}
      PutImagenXYSinWhere320(Esp.x,Esp.y,Esp.iEsp[Esp.Tipo],255,wPant);
    if Bola.Estela then {Estela bola en directos}
      for i:=0 to MaxEstela do
        begin
          j:=i div 2;
          if j>2 then
            j:=2;
          PutImagenXYSinWhere320(Bola.Est[i].x,Bola.Est[i].y,Bola.iEst[j],255,wPant);
        end;
    PutImagenXYSinWhere320(Bola.x,Bola.y,Bola.iBola,255,wPant);
    flip(wPant,SegA000);

    PausaPong(150);


    Frames:=Frames+1;
    if Frames>=100 then
      begin
        Frames:=0;
        FramesSeg:=100 / TpoPasado;
      end;


    GolBola(Especial);

  until KeyDown[escScan];
end;



begin {*******************  P R I N C I P A L ******************************}

randomize;

wPant:=CrearPantalla;
wFondo:=CrearPantalla;

IniciaSVGA256(0,'',Error);

NewKeyInt;


{Dibuja fondo}
clsWhere(0,wFondo);
LineWhere(0,0,MaxX,0,15,wFondo);
LineWhere(0,0,0,MaxY,15,wFondo);
LineWhere(MaxX,0,MaxX,MaxY,15,wFondo);
LineWhere(0,MaxY,MaxX,MaxY,15,wFondo);
LineWhere(159,0,159,MaxY,15,wFondo);
LineWhere(160,0,160,MaxY,15,wFondo);


{Carga imagenes}
LoadImagenPcxXY('pala.pcx','',0,0,5,19,Pala.iPala[0],Error);
LoadImagenPcxXY('pala.pcx','',12,0,17,29,Pala.iPala[1],Error);
LoadImagenPcxXY('pala.pcx','',24,0,30,39,Pala.iPala[2],Error);

LoadImagenPcxXY('pala.pcx','',6,0,11,19,Pala2.iPala[0],Error);
LoadImagenPcxXY('pala.pcx','',18,0,23,29,Pala2.iPala[1],Error);
LoadImagenPcxXY('pala.pcx','',31,0,37,39,Pala2.iPala[2],Error);

LoadImagenPcxXY('bola.pcx','',0,0,6,6,Bola.iBola,Error);
for i:=0 to 2 do
  LoadImagenPcxXY('bola.pcx','',i*7,7,i*7+6,13,Bola.iEst[i],Error);

LoadImagenPcxXY('esp.pcx','',0,0,13,8,Esp.iEsp[0],Error);
LoadImagenPcxXY('esp.pcx','',0,9,13,17,Esp.iEsp[1],Error);
LoadImagenPcxXY('esp.pcx','',0,18,13,26,Esp.iEsp[2],Error);
LoadImagenPcxXY('esp.pcx','',0,27,13,35,Esp.iEsp[3],Error);

CargaPaleta; {la coge de esp.pcx}


{Opciones}
Opc.Jugadores:=1;
Opc.Tcl.Arr:=UpScan;
Opc.Tcl.Aba:=DownScan;
Opc.Tcl.Izq:=LeftScan;
Opc.Tcl.Der:=RightScan;
Opc.Tcl2.Arr:=ScanOf('w');
Opc.Tcl2.Aba:=ScanOf('s');
Opc.Tcl2.Izq:=ScanOf('a');
Opc.Tcl2.Der:=ScanOf('d');
Opc.Pausa:=1000;


{Previo}
Presentacion;
Presentacion2;
Presentacion3;


repeat
  Cursor:=Menu;
  if Cursor=2 then
    begin
      Presentacion4;
      Jugar;
    end;
until Cursor=4;


OldkeyInt;

end.
