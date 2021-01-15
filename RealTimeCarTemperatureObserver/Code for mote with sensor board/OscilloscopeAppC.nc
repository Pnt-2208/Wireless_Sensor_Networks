/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Oscilloscope demo application. Uses the demo sensor - change the
 * new DemoSensorC() instantiation if you want something else.
 *
 * See README.txt file in this directory for usage instructions.
 *
 * @author David Gay
 */
configuration OscilloscopeAppC { }
implementation
{
  components OscilloscopeC, 
  MainC, 
  ActiveMessageC, 
  LedsC,
  SounderC,				/*Speaker*/
  new TimerMilliC(), 			/*Timer*/
  new AccelXC() as Sensor, 		/*Accelerometer*/
  new TempC() as Sensor1, 		/*Temperature Sensor*/
  new MicC() as Sensor2,		/*Microphone*/
  new AMSenderC(AM_OSCILLOSCOPE), 
  new AMReceiverC(AM_OSCILLOSCOPE);

  OscilloscopeC.Boot -> MainC;
  OscilloscopeC.RadioControl -> ActiveMessageC;
  OscilloscopeC.AMSend -> AMSenderC;
  OscilloscopeC.Receive -> AMReceiverC;
  OscilloscopeC.Timer -> TimerMilliC;
  OscilloscopeC.Read -> Sensor;			
  OscilloscopeC.Sensor1 -> Sensor1;
  OscilloscopeC.Sensor2 -> Sensor2;
  OscilloscopeC.Leds -> LedsC;
  OscilloscopeC.Mts300Sounder -> SounderC;
  
}
