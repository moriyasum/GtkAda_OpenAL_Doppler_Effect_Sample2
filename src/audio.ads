
with Gtk.Widget;      use Gtk.Widget;
with Gtk.Handlers;    use Gtk.Handlers;
with Interfaces;      use Interfaces;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Text_IO; use Ada.Strings.Unbounded.Text_IO;
with Ada.Sequential_IO; --use Ada.Sequential_IO;  --cannot use "use" for this generic package

with OpenAL.Context;  use OpenAL.Context; --use is needed
with OpenAL.List;
with OpenAL.Types;
with OpenAL.Buffer;
with OpenAL.Error;    use OpenAL.Error;   --use is needed
with OpenAL.Listener;
with OpenAL.Source;
with OpenAL.Thin;
with OpenAL.Global;   use OpenAL.Global;   --for Get_Doppler_Factor


Package Audio is

   package Handlers is new Gtk.Handlers.Callback --Need with Gtk.Handlers
     (Widget_Type => Gtk_Widget_Record);    --Need with Gtk.Widget

   Function Test_Error (Display_Message : String) return Boolean;

   WAVE_FILE_NAME : constant string :=  "testsound.wav";
   Function LoadWaveFile(
      WaveFile: in  String;        -- WAV File name string
      Format :  out Unsigned_16;   --PCM=01,00
      Data :    out OpenAL.Buffer.Sample_Array_16_t;
      Length :  out Unsigned_32;   --Byte, Only Data portion=(05..08)+8-44
      Freq :    out OpenAL.Types.Size_t;
      Channel : out Unsigned_16;   --1ch=01,00, 2ch=02,00
      Sample :  out Unsigned_16    --16bit=10,00
   ) Return Boolean;

   Procedure ALSound_Initialize;

   Procedure ALSound_Process;
---------------------------------------
--CONSTANT
---------------------------------------
   LISTENER_GAIN : constant := 10.0;

---------------------------------------
-- GLOBAL VARIABLES
---------------------------------------
   CX_Devicet : OpenAL.Context.Device_t;   --Used when Open and Close Audio Context
   Sound_Source : OpenAL.Source.Source_t;
   Sound_Source_Array : OpenAL.Source.Source_Array_t(1..1);


end Audio;
