
with Ada.Text_IO;     use Ada.Text_IO;
with Gui;      use Gui;


Package body Audio is

---------------------------------------------------------
-- Function: Display OpenAL Procedure/Function Result
--   In: OpenAL result Code number
--   Out: Boolean result. Good=True, Error=False
-- Note; Function Get_Error doesn't work perfectly
-- Note; Error Codes are different between in Spec and in Code.
---------------------------------------------------------
Function Test_Error (Display_Message : String) return Boolean is
   Result : Boolean;
   Errort : OpenAL.Error.Error_t;
begin
   Errort := OpenAL.Error.Get_Error;
   If(Errort = No_Error) then
      Result := True;
   else
      Result := False;
   end if;
   Put(Display_Message & "  ");
   Case Errort is
      when No_Error          => Put_Line("GOOD: SUCCESS");
      when Invalid_Name      => Put_Line("ERROR!!! Invalid_Name####################");
      when Invalid_Enumeration => Put_Line("ERROR!!! Invalid_Enumeration###########################");
      when Invalid_Value     => Put_Line("ERROR!!! Invalid_Value####################");
      when Invalid_Operation => Put_Line("ERROR!!! Invalid_Opearation######################");
      when Out_Of_Memory     => Put_Line("ERROR!!! Out_Of_Memory###################");
      when Unknown_Error     => Put_Line("ERROR!!! Unknown_Error###################");
      when Others            => Put_Line("ERROR!!! UNDEFINED ERROR######################");
   end case;
   Return Result;
end Test_Error;


---------------------------------------------------------
-- Function: Open WAV file and store the parameters and data
--   IN: File name string and output valiable addresses,
--   OUT: Boolean result Good=True, Error=False
---------------------------------------------------------
Function LoadWaveFile (
   WaveFile: in String;        -- File name string
   Format : out Unsigned_16;   --PCM=01,00
   Data : out OpenAL.Buffer.Sample_Array_16_t;
   Length : out Unsigned_32;    --Byte, Only Data portion=(05..08)+8-44
   Freq : out OpenAL.Types.Size_t;
   Channel : out Unsigned_16;    --1ch=01,00, 2ch=02,00
   Sample : out Unsigned_16   --16bit=10,00
   ) Return Boolean is   --True=Success, False=Error
 ---
   type Sample_16_t is range -32768 .. 32767;
   for Sample_16_t'Size use 16;
   package UWI_IO is new Ada.Sequential_IO (Unsigned_16);
   use UWI_IO;
   FT :   UWI_IO.File_Type;
   WAttrb : array (1..50) of Unsigned_16 := (1..50 => 0);  --Wave file Attribute portion
   Cnt :  Integer;
   Index : array (1..2) of Unsigned_16 := (Others=>0);     --"data" search buffer in WAV file header
   K1,K2 :     Unsigned_16;
   Data1U16 :  Unsigned_16;
   Data1S16t : OpenAL.Buffer.Sample_16_t;
   DataCnt :   Integer;

Begin
   Begin   --File open
      UWI_IO.Open (File=>FT, Mode=>In_File, Name=>WaveFile);    --Text_IO Open doesnot work for Binary file
   exception
      when others=>
         Put_Line("ERROR!!!  WAV File cannot Open");
         raise;
   end;   --File open end

   Put_Line("File Open done");
   Cnt := 1;
   while not End_Of_File (FT) loop
      Read(FT, WAttrb(Cnt));
      Index(1):=Index(2); Index(2):=WAttrb(Cnt);
      exit when ((Index(1)=16#6164#) and (Index(2)=16#6174#));            -- Found "data"=Subchunk2 ID
      If (Cnt=50-2) then
         Put_Line("ERROR WAV file Index is too long");
         Return False;
      end if;   --WAVE FORMAT ERROR
      Cnt := Cnt+1;
   end loop;
--"data" was found, then get next Subchunk2Size
   Read(FT, K1);
   WAttrb(Cnt):=K1;    -- Lower 16bit of Data number of BYTE Length 32bit
   Cnt := Cnt + 1;
   Read(FT, K2);
   WAttrb(Cnt):=K2;    -- Upper 16bit
   Length := Unsigned_32(K2)*65536 + Unsigned_32(K1);   -- Data Length, number of BYTE

   DataCnt := 1;
   while not End_Of_File (FT) loop
      Read(FT, Data1U16);
      if(Data1U16<32768) then Data1S16t := OpenAL.Buffer.Sample_16_t(Data1U16);       --Positive
      else Data1S16t := OpenAL.Buffer.Sample_16_t(-(Integer_16(NOT Data1U16) + 1));   --Negative value
      end if;
      Data(OpenAL.Buffer.Sample_Size_t(DataCnt)) := Data1S16t;   --Store data
      DataCnt := DataCnt + 1;
      If (DataCnt > Integer(Length)/2+1) then       --DataCnt=16bit, Length=8bit
         Put_Line("ERROR WAV file DATA is too long");
         Return False;
      end if;
   end loop;

   Put_Line("DataCnt=" & Integer'Image(DataCnt) & "  Integer(Length)/2+1=" & Integer'Image(Integer(Length)/2+1));
   --Result is: DataCnt= 220501  Integer(Length)/2+1= 220501

   Close (FT);             -- File close
   Format := WAttrb(11);   --PCM=0001=01,00
   Freq := OpenAL.Types.Size_t(Unsigned_32(WAttrb(13)) + Unsigned_32(WAttrb(14))*65536);
   Channel := WAttrb(12);
   Sample := Wattrb(18);
   Return True;   --Success End
End LoadWaveFile;


----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
-- Sound Initialize
--   Open Wav file and setup all parameters, but
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
Procedure ALSound_Initialize is

   Bool : Boolean;
   NrPlayback_Devices  : Integer;
   Vector_Cnt : Integer;
   Playback_StrVectt   : OpenAL.List.String_Vector_t;
   UB_OpenAL_Version   : Unbounded_String;
   UB_Default_Play     : Unbounded_String;
   UB_Playback_Devices : Unbounded_String;

   CX_Contextt : OpenAL.Context.Context_t;
   Set_Active_Context  : Boolean;

   Source_Set_Position : OpenAL.Types.Vector_3f_t := (0.0, 1.0, 0.0);         --X,Y,Z
   Source_Set_Velocity : OpenAL.Types.Vector_3f_t := (0.0, 0.0, 0.0);         --X,Y,Z
   Source_Set_Direction: OpenAL.Types.Vector_3f_t := (0.0, 1.0, 0.0);         --X,Y,Z
   Listener_Set_Position : OpenAL.Types.Vector_3f_t := (0.0, 2.0, 0.0);         --X,Y,Z
   Listener_Set_Velocity : OpenAL.Types.Vector_3f_t := (0.0, 0.0, 0.0);         --X,Y,Z
   Listener_Orientation_Forward : OpenAL.Types.Vector_3f_t := (0.0, 1.0, 0.0);  --X,Y,Z
   Listener_Orientation_Up : OpenAL.Types.Vector_3f_t := (0.0, 0.0, 1.0);       --X,Y,Z

   SoundWaveFileName : String := WAVE_FILE_NAME;  --"testsound.wav"
   Result_WaveFileOPen : Boolean;
   WAV_Format : Interfaces.Unsigned_16;   --PCM=01,00
   WAV_Data : OpenAL.Buffer.Sample_Array_16_t(1..1000000); --WAV File Word Max Capacity
   WAV_Length : Unsigned_32;    --Only Data portion number of Byte (chunk2 data area)
   WAV_Freq : OpenAL.Types.Size_t;
   WAV_Channel : Unsigned_16;    --1ch=01,00, 2ch=02,00
   WAV_Sample : Unsigned_16;   --16bit=10,00
   Buffer_Arrt : OpenAL.Buffer.Buffer_Array_t (1..1000000);   --WAV File Word Max Capacity
   ProcessedNr : Natural;

begin

   Put_Line("OpenAL Program Sample1");

--***********
--Get OpenAL Version number
--***********
--  UB_OpenAL_Version := To_Unbounded_String(OpenAL.Global.Vendor);    --"Version" causes error. Not supported.

--***********
--Get_Default_Device_Specifier  (Default Playback)
--***********
   --use To_Unbounded_String, because the length is unknown
   UB_Default_Play:=To_Unbounded_String(OpenAL.Context.Get_Default_Device_Specifier);
   Put_Line("Default Playback=" & UB_Default_Play);

--***********
--Get_All_Device_Specifiers  (All Playbacks)
--***********
   Playback_StrVectt := OpenAL.Context.Get_Available_Playback_Devices;
   Vector_Cnt := 1;

   Put_Line("");
   Bool := OpenAL.List.String_Vectors.Is_Empty(Playback_StrVectt);   --TRUE=EMPTY
   NrPlayback_Devices := Integer(OpenAL.List.String_Vectors.Length(Playback_StrVectt));
   If(Bool) then   --EMPTY
      Put_Line("No Playback Device, N=" & Integer'Image(NrPlayback_Devices));
   else
      Put_Line("Playback Devices N=" & Integer'Image(NrPlayback_Devices));
      Vector_Cnt := 1;
      Loop
         UB_Playback_Devices := To_Unbounded_String(Playback_StrVectt(Vector_Cnt));
         Put_Line("Playback Devices Length=" & Integer'image(Length(UB_Playback_Devices)));
         Put_Line("Playback Device#" & Integer'Image(Vector_Cnt) & "=" & UB_Playback_Devices);
         Vector_Cnt := Vector_Cnt + 1;
         Exit when Vector_Cnt >= NrPlayback_Devices;
      end loop;
   end if;

 --****************
 -- OPEN Playback Device
 -- C:  device = alcOpenDevice(NULL); // open default device
 ---***************
   CX_Devicet := OpenAL.Context.Open_Device ("OpenAL Soft");  --"OpenAL Soft")
   Put_Line("UB_Playback_Device=" & UB_Playback_Devices);
   if (CX_Devicet = Invalid_Device) then   --Ref file: openal-alc_thin.ads
      Put_Line("BAD-Invalid Device!!! Cannot open Playback Device*******");
   else
      Put_Line("GOOD, Open Output Device Success");
   end if;

   --****************
   -- Create Context
   -- C: context=alcCreateContext(device,NULL); // create context
   --****************
   CX_Contextt := Create_Context (CX_Devicet);
   if (CX_Contextt = Invalid_Context) then   --Ref file: openal-alc_thin.ads
      Put_Line("BAD-Invalid Context!!! Cannot Create Context *******");
   else
      Put_Line("GOOD, Create Context Success");
   end if;


   --****************
   -- Set Active Context
   -- C: alcMakeContextCurrent(context); // set active context
  --****************
   Set_Active_Context := Make_Context_Current(CX_Contextt);
   if (Set_Active_Context = False) then
      Put_Line("ERROR Set Active Context!!! Cannot Set Active Context *******");
   end if;
   If (Test_Error("Set_Active_Context") = False) then goto END_OF_PROGRAM; end if;

--****************
-- Load testsound.wav
-- Same the old loadWAVFile("testsound.wav",&format,&data,&Length,&freq,&loop);----This is Obsolete
--****************
   Result_WaveFileOpen := LoadWaveFile(
      SoundWaveFileName,
      WAV_Format,           -- PCM=0001
      WAV_Data,             -- Sample_Array_16_t(1)
      WAV_Length,           -- Number of Wave data Byte
      WAV_Freq,             -- Frequency_t
      WAV_Channel,
      WAV_Sample);

   If (Result_WaveFileOpen=False) then
      Put_Line("Wave file Open ERROR");
      goto END_OF_PROGRAM;
   end if;

   Put_Line("Sound File=" & SoundWaveFileName);
   Put("Format=" & Unsigned_16'image(WAV_Format));
   If(WAV_Format=1) then Put_Line(" PCM"); else Put_Line(" Some format"); end if;
   Put_Line("WAV Data Length=" & Unsigned_32'image(WAV_Length) & " Byte");
   Put_Line("Sampling Freq=" & OpenAL.Types.Size_t'image(WAV_Freq) & "Hz");
   Put_Line("Channel=" & Unsigned_16'image(WAV_Channel));
   Put_Line("Sample=" & unsigned_16'image(WAV_Sample) & "bit");

--****************
--Generate Buffers
--     C:  alGenBuffers(NUM_BUFFERS, g_Buffers);
--    Ada:  procedure Generate_Buffers (Buffers : in out Buffer_Array_t);
--    The Generate_Buffers procedure generates Buffers'Length buffers.
--****************
   OpenAL.Thin.Gen_Buffers
     (Size => OpenAL.Types.Size_t(WAV_Length/2),   --Set number of Words
      Buffers => Buffer_Arrt(1)'Address);

   Put_Line("Generated Buffer, WAV_Length=" & Unsigned_32'Image(WAV_Length) & " Byte");

--****************
--Copy WAV data into AL Buffer 0
--   C: alBufferData(g_Buffers[0],format,data,Size(number of Bytes),freq);
--   This proc is not written in the manual, it is in OpenAL.Thin source.
--   It can set Size freely, so it is good to define maximum WAV buffer
--****************
   OpenAL.Thin.Buffer_Data(
     Buffer_ID => 1,                    --Types.Unsigned_Integer_t;
     Format    => OpenAL.Thin.AL_FORMAT_MONO16,     --Types.Enumeration_t;
     Data      => WAV_Data(1)'Address,              --system.Address;
     Size      => OpenAL.Types.Size_t(WAV_Length),   --Types.Size_t;==This Length is adjustable
     Frequency => WAV_Freq                         --Types.Size_t;
   );

--****************
-- Generate Sources
--    C: alGenSources((ALuint)1, &source); //generates one or more sources, n=number
--    If error: alDeleteBuffers(NUM_BUFFERS, g_Buffers) ???? This was not written in the sample program
--****************
   OpenAL.Source.Generate_Sources (Sound_Source_Array);   --Gval.Sound_Source_Array(1..1) only one array
   Sound_Source := Sound_Source_Array(1);   --Sound_Source:Source_t
   If (Test_Error("Generate-Sources (Gval.Sound_Source_Array)") = False) then goto END_OF_PROGRAM; end if;

   OpenAL.Source.Get_Buffers_Processed (Sound_Source, ProcessedNr);
   Put_Line("1 Number of Processed buffers=" & Natural'image(ProcessedNr));   --Nu=0 Just to monitor
   OpenAL.Source.Get_Buffers_Queued (Sound_Source, ProcessedNr);
   Put_Line("Number of Processed buffers Queued=" & Natural'image(ProcessedNr));   --Queued=0 just to monitor
   If(OpenAL.Source.Is_Valid(Sound_Source)=True) then Put_Line("Is_Vlaid=True"); else Put_Line("Is_Valid=False"); end if;

---****************
--Attach buffer to source
--   C: alSourcei(source[0], AL_BUFFER, g_Buffers[0]);
--   procedure Set_Current_Buffer
--  (Source : in Source_t;
--   Buffer : in OpenAL.Buffer.Buffer_t);
--****************
   OpenAL.Source.Set_Current_Buffer
     (Sound_Source,
      Buffer_Arrt(1));

   Put_Line("Attached buffer to Source");
   OpenAL.Source.Get_Buffers_Processed (Sound_Source, ProcessedNr);
   Put_Line("2 Number of Processed buffers=" & Natural'image(ProcessedNr));   --Nr=0 just to monitor
   OpenAL.Source.Get_Buffers_Queued (Sound_Source, ProcessedNr);
   Put_Line("Number of Processed buffers Queued=" & Natural'image(ProcessedNr));   --Queued=1 just to monitor
   If(OpenAL.Source.Is_Valid(Sound_Source)=True) then Put_Line("Is_Vlaid=True"); else Put_Line("Is_Valid=False"); end if;

--****************
-- Set SOURCE Position, Velocity, Direction
--    procedure Set_Position_Float_List
--   (Source    : in Source_t;
--    Position  : in Types.Vector_3f_t);
--****************
   OpenAL.Source.Set_Position_Float_List(Sound_Source, Source_Set_Position);
   If (Test_Error("Set Source Set_Position_Float_List") = False) then goto END_OF_PROGRAM; end if;
   OpenAL.Source.Set_Velocity_Float_List(Sound_Source, Source_Set_Velocity);
   If (Test_Error("Set Source Set_Velocity_Float_List") = False) then goto END_OF_PROGRAM; end if;
   OpenAL.Source.Set_Direction_Float_List(Sound_Source, Source_Set_Direction);
   If (Test_Error("Set Source Set_Direction_Float_List") = False) then goto END_OF_PROGRAM; end if;

--****************
-- Set LISTENER Position, Velocity, Direction
--    procedure Set_Position_Float_List
--   (Position : in Types.Vector_3f_t);
---****************
   OpenAL.Listener.Set_Position_Float_List(Listener_Set_Position);   --X,Y,Z  set the position of the listener
   If (Test_Error("Set Listener Set_Position_Float_List") = False) then goto END_OF_PROGRAM; end if;
   OpenAL.Listener.Set_Velocity_Float_List(Listener_Set_Velocity);   --X,Y,Z  set the velocity of the listener
   If (Test_Error("Set Listener Set_Velocity_Float_List") = False) then goto END_OF_PROGRAM; end if;
   OpenAL.Listener.Set_Orientation_Float(Listener_Orientation_Forward, Listener_Orientation_Up);
   If (Test_Error("Set Listener Orientation Fwd/Up") = False) then goto END_OF_PROGRAM; end if;
---****************

--****************
-- Set Listener GAIN
--****************
   OpenAL.Listener.Set_Gain(LISTENER_GAIN);

<< END_OF_PROGRAM >>   -- label for goto when Error

end ALSound_Initialize;



-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
-- Output Audio Control Process
--    Called by Timer Interrupt when Start_Flag /= 0
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
Procedure ALSound_Process is

Begin
-- Set Source, Listener Position
   OpenAL.Source.Set_Position_Float(Sound_Source, OpenAL.Types.Float_t(S2SndPos_X) , OpenAL.Types.Float_t(S2SndPos_Y) , 0.0);  -- Left(-) to Right(+), XYZ Float
   OpenAL.Listener.Set_Position_Float(0.0 , 0.0 , 0.0);  -- Listner is Origin=0,0,0. Source uses Relative distance from Listener.

-- Set Velocity
   OpenAL.Source.Set_Velocity_Float(Sound_Source, OpenAL.Types.float_t(Vel_Snd_X), OpenAL.Types.float_t(Vel_Snd_Y), 0.0);  -- Increase from 0, XYZ Float

end ALSound_Process;
 ----------------------------------------------------------------------------------------------------------

End Audio;

