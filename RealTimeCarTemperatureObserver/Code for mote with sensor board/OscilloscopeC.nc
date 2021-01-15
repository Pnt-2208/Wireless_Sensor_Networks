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
 * Oscilloscope demo application. See README.txt file in this directory.
 *
 * @author David Gay
 */
#include "Timer.h"
#include "Oscilloscope.h"

module OscilloscopeC @safe()
{
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface AMSend;
    interface Receive;
    interface Timer<TMilli>;
    interface Read<uint16_t>;				//Accelerometer
    interface Leds;
    interface Read<uint16_t> as Sensor1;		//Temp Sensor
    interface Read<uint16_t> as Sensor2;		//Mic Sensor
    interface Mts300Sounder;				//Speaker
  }	
}
implementation
{
  message_t sendBuf;
  bool sendBusy;

  /* Current local state - interval, version and accumulated readings */
  oscilloscope_t local;

  uint8_t reading; 	/* 0 to NREADINGS */
  uint8_t TempV;	/* temperature array, also 0 to NREADINGS*/
  uint16_t avg;		/* Average fot accelerometer*/
  uint16_t Tavg;	/*Average for temp readings*/
  uint8_t i=0;		/*used for average loop*/
 

 
  /* When we head an Oscilloscope message, we check it's sample count. If
     it's ahead of ours, we "jump" forwards (set our count to the received
     count). However, we must then suppress our next count increment. This
     is a very simple form of "time" synchronization (for an abstract
     notion of time). */
  bool suppressCountChange;

  // Use LEDs to report various status issues.
  void report_problem() { call Leds.led0Toggle(); }
  void report_sent() { call Leds.led1Toggle(); }
  void report_received() { call Leds.led2Toggle(); }

  event void Boot.booted() {
    local.interval = DEFAULT_INTERVAL;
    local.id = TOS_NODE_ID;
    if (call RadioControl.start() != SUCCESS)
      report_problem();
  }

  void startTimer() {
    call Timer.startPeriodic(local.interval);
    reading = 0;
    TempV = 0;
    avg = 0;
    Tavg = 0;
    local.Alarm = 0;

  }

  event void RadioControl.startDone(error_t error) {
    startTimer();
  }

  event void RadioControl.stopDone(error_t error) {
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    oscilloscope_t *omsg = payload;

    report_received();

    /* If we receive a newer version, update our interval. 
       If we hear from a future count, jump ahead but suppress our own change
    */
    if (omsg->version > local.version)
      {
	local.version = omsg->version;
	local.interval = omsg->interval;
	startTimer();
      }
    if (omsg->count > local.count)
      {
	local.count = omsg->count;
	suppressCountChange = TRUE;
      }

    return msg;
  }
/*
     - if local sample buffer is full, send accumulated samples
     - read next sample
  */
  event void Timer.fired() {
    if (reading == NREADINGS)
      {	
	for (i=0; i<NREADINGS ; i++) {
    	  avg += local.readings[i];		
	}
	avg = avg/NREADINGS;
	if((avg < 0x01D6 || avg > 0x1D7)== FALSE)	/*min threshold*/
	{
		
		/*start checking inputs from temp sensor*/
		/*loop to get avg*/

			for (i=0; i<NREADINGS ; i++)
			{
			  Tavg += local.TempVs[i];
			}
			Tavg = Tavg/NREADINGS;

			/*If temp is above threshold
			then set message flag to 1*/
		
			if (Tavg > 0x220)
			{
			//call Mts300Sounder.beep(10);
			local.Alarm =1;
				
				if (local.Mics > 0x190){
				call Mts300Sounder.beep(100);}
					
			}
	}	

		if (!sendBusy && sizeof local <= call AMSend.maxPayloadLength())

		  {
		    // Don't need to check for null because we've already checked length
	 	   // above
	 	   memcpy(call AMSend.getPayload(&sendBuf, sizeof(local)), &local, sizeof local);
	  	  if (call AMSend.send(AM_BROADCAST_ADDR, &sendBuf, sizeof local) == SUCCESS)
	  	    sendBusy = TRUE;
	 	 
	}
	if (!sendBusy)
	  report_problem();
	avg =0;
	Tavg =0;
	reading = 0;
	TempV = 0;
	local.Alarm = 0;
	
	/* Part 2 of cheap "time sync": increment our count if we didn't
	   jump ahead. */
	if (!suppressCountChange)
	  local.count++;
	suppressCountChange = FALSE;
      }
// reading from a accel sensor
    if (call Read.read() != SUCCESS)
      report_problem();
//reading from temp sensor
   if (call Sensor1.read() != SUCCESS)
      report_problem();
//reading from mic 
   if (call Sensor2.read() != SUCCESS)
      report_problem();
  }

  event void AMSend.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      report_sent();
    else
      report_problem();

    sendBusy = FALSE;
  }
//Accel
  event void Read.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
	data = 0xffff;
	report_problem();
      }
    if (reading < NREADINGS) 
      local.readings[reading++] = data;
   }
  //temp
  event void Sensor1.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
		data = 0xffff;
	report_problem();
      }
    if (TempV < NREADINGS) 
      local.TempVs[TempV++] = data;
   }
//Mic
  event void Sensor2.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS)
      {
		data = 0xffff;
	report_problem();
      } 
      local.Mics = data;
   }


}
