

with Gui;          use Gui;
with Audio;        use Audio;

Package body Tintr is
--------------------------------------------------------
--------------------------------------------------------
--TIMER INTERRUPT
--------------------------------------------------------
--------------------------------------------------------
function Timer_Intr (Pbar : Gtk_Progress_Bar) return Boolean is

begin
   If(Start_Flag =0) then    --Flag=0  Nothing to do
      TimerIntrCounter := TimerIntrCounter + 1;
      TimeCnt := 0;
      Time_X  := 0.0;
      Time_Y  := 0.0;
      Return True;
   end if;

--------------------
-- Display Graphics and Audio Output
--------------------     
   Display_Plane (TimeCnt);       --Calculate and Move Plane
   ALSound_Process;    --Set Audio Source & Listner Position XYZ and Source Velocity XYZ
         
   if (Pause_Flag=1) then   --Pause, then do nothing (keep audio and position)
      TimerIntrCounter := TimerIntrCounter + 1;
      Return True;
   end if;      

   if ((Start_Flag=1) or (Start_Flag=3) or (Start_Flag=5)) then
      --Button was pressed, Begin Audio
      OpenAL.Source.Set_Looping(Audio.Sound_Source, Looping => True);   --Manual doc is wrong 
      OpenAL.Source.Play (Audio.Sound_Source_Array(1));

      Put_Line("Play(Sound_Source)");

      If ((Start_Flag=1) or (Start_Flag=5)) then
         TimeCnt := 0;    --Initialize         
      end if;
      Start_Flag := Start_Flag + 1;   --Flag 1=>2, 3=>4, 5=>6
   end if;
         
--STEP mode and Counter is busy
   If (Start_Flag=4) then   --STEP mode   
      If (Step_Counter /= 0) then            
         Step_Counter := Step_Counter - 1;
         If (Step_Counter = 0) then 
            Pause_Flag := 1;     
            Set_Label (Button_Step, "Step");   --Turn to stop STEP             
            Parse (ButtonColor, "Black", Dummy_Boolean); 	         
            Gtk.Widget.Override_Color(Gtk_Widget(Button_Step), Gtk_State_Flag_Normal ,ButtonColor);   --Button Character Color is switched to Red, Modify is obsolete
            end if;
      end if;   
   end if; --End Start_Flag=1,3,5   

   TimerIntrCounter := TimerIntrCounter +1;
   TimeCnt := TimeCnt + 1;
   Time_X := Time_X +1.0; 
   If ((Time_X * float(TINTR_PITCH) /1000.0) >= float(Get_Value(TIME_CYCLE_X))) then
--Timer(X) is full, Plane is at the start position, then one loop was finished. 
      Time_X := 0.0;
      If (Start_Flag=2) then   --Single loop complted, then stop the process.
   --Single mode and End cycle. Finish Single process
         Start_Flag := 0;
         Pause_Flag := 0;
         Set_Label (Gui.Button_Single, "Single");
         Parse (ButtonColor, "Black", Dummy_Boolean); 	         
         Gtk.Widget.Override_Color(Gtk_Widget(Button_Single), Gtk_State_Flag_Normal ,ButtonColor);   --Button Character Color is switched to Red, Modify is obsolete
         Set_Label (Gui.Button_Loop, "Loop");
         Parse (ButtonColor, "Black", Dummy_Boolean); 	         
         Gtk.Widget.Override_Color(Gtk_Widget(Button_Loop), Gtk_State_Flag_Normal ,ButtonColor);   --Button Character Color is switched to Red, Modify is obsolete
         Set_Label (Button_Step, "Step");
         Parse (ButtonColor, "Black", Dummy_Boolean); 	         
         Gtk.Widget.Override_Color(Gtk_Widget(Button_Step), Gtk_State_Flag_Normal ,ButtonColor);   --Button Character Color is switched to Red, Modify is obsolete
                 
         OpenAL.Context.Close_Device (Audio.CX_Devicet);  -- CLOSE "OpenAL Soft" and stop sound
         Return True;
      end if;
--On the way processing         
   end if;
   Time_Y := Time_Y +1.0;
   If ((Time_Y * float(TINTR_PITCH) /1000.0) >= float(Get_Value(TIME_CYCLE_Y))) then
      Time_Y := 0.0;
   end if;
 
   Return True;
end Timer_Intr;

End Tintr;


