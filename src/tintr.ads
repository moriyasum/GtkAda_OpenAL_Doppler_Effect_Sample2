

with OpenAL.Context; 
with OpenAL.List; 
with OpenAL.Types;
with OpenAL.Buffer; 
with OpenAL.Error;   
with OpenAL.Listener; 
with OpenAL.Source; 
with OpenAL.Thin;   

with Gtk.Widget;         use Gtk.Widget;
with Gtk.Button;         use Gtk.Button;
with Gtk.Enums;          use Gtk.Enums;
with Gtk.Spin_Button;    use Gtk.Spin_Button;
with Gtk.Progress_Bar;   use Gtk.Progress_Bar;  --Timer Interrupt
with Ada.Real_Time;      use Ada.Real_Time;         --Timer Interrupt
with Glib.Main;          use Glib.Main;  --Timer Interrupt  Time_Cb.Timeout_Add
with Gdk.RGBA;           use Gdk.RGBA;
with Text_IO;            use Text_IO;

package Tintr is

   function Timer_Intr (Pbar : Gtk_Progress_Bar) return Boolean;   
   
   TimerIntrDuration : Time_Span;  --need with Ada.Real_Time
   TimerIntrCounter : integer := 0;
   TINTR_PITCH : Constant := 100;   --100=100ms, 200=200ms
   TIMECNT_DRAW_PRESET : Constant := 4;  --In Draw, countdown TimeCnt_Draw preset value
   TimeCnt : Integer := TIMECNT_DRAW_PRESET;   --Playback Time/Location/Speed Counter
   TimerIntrCounter_Before : Integer :=0;   --In Draw, check if TimeCnt is same or changed
   TimeCnt_Draw   : integer :=0;   --In Draw, count how many Draw is accepted in a TimeCnt

   Direction : Integer := 0;  --0=Positive(to right), 1=Negative (to Left)
   Datatype_dummy : Gtk_Progress_Bar;    --Timer interrupt 
   EndFlag : Integer;   --Playback loop End Flag
   Gid_dummy   : G_Source_Id;     --Timer interrupt
   Start_Flag : Integer := 0;   --0=stop,1=Single Start,2=Single busy, 3=Step Start, 4=Step busy,5=Loop start,6=Loop busy
   Pause_Flag : Integer := 0;   --default=0, Pause=1

end Tintr;
