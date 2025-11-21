import express, { Request, Response } from 'express';
import cors from 'cors';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import bcrypt from 'bcrypt';
import xss from 'xss';
import fetch from 'node-fetch';
import dotenv from 'dotenv';
import nodemailer from 'nodemailer';
import fs from 'fs-extra';
import { supabase } from '../utils/supabaseClient'; // adjust path as needed
import { PrismaClient } from '@prisma/client'
import { SupabaseClient } from '@supabase/supabase-js';
import { Buffer } from 'buffer';
import { URLSearchParams } from 'url';


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< UPDATE FITBIT ACCESS >-----------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

interface fitBitBody{
  email: string,
  fitBitAccess: boolean,
}

export const updateFitBitAccess = async (req: Request<{}, {}, fitBitBody>, res: Response) =>{
    
  const {email, fitBitAccess} = req.body;

  console.log('updateFitBitAccess email:', email)
  console.log('updateFitBitAccess fitBitAccess:', fitBitAccess)

  if(!email || email == null){
      console.log('updateFitBitAccess: no email received from the front end');
      return res.status(400).json({
        message: 'Email is required to update FitBit access',
        success: false,
      });
  }

  let result = await supabase.from('users').update({fitbitaccess: fitBitAccess}).eq('email', email).select();

  if(result.error){
    console.log('updateFitBitAccess could not find a user associated with that email', result.error);
    return res.status(400).json({message: 'updateFitBitAccess could not find a user associated with that email', success: false});
  }

   if (result.count === 0 || !result.data){
       console.log('No rows matched for update');
    return res.status(404).json({
      message: 'No matching user found',
      success: false,
    });
  }

  if(fitBitAccess == false){
    // get the users id so we can match it with the access token and delete/revoke it 
      try{
      
      
         let user = await supabase.from('users').select('id').eq('email', email).single();

         console.log('Fetched user ID:', user.data?.id);

         if (!user.data || !user.data.id) {
            console.log('No user found for email:', email);
            return res.status(404).json({ message: 'User not found', success: false });
          }

         const tokenRecord = await supabase.from('fitbit_tokens').select('access_token').eq('user_id', user.data.id).single();
       

          if (!tokenRecord.data?.access_token) {
             return res.status(404).json({ message: 'No access token found', success: false });
            }

       const credentials = Buffer.from(`${process.env.FITBIT_CLIENT_ID}:${process.env.FITBIT_CLIENT_SECRET}`).toString('base64');

      
      // we also need to revoke form the api via POST https://api.fitbit.com/oauth2/revoke 
      
            const response = await fetch('https://api.fitbit.com/oauth2/revoke', {
               method: 'POST',
               headers: {
                 'Content-Type': 'application/x-www-form-urlencoded',
                 'Authorization': `Basic ${credentials}`,
                },
               body: `token=${tokenRecord.data.access_token}`,
            });
       
          if (!response.ok) {
              const errorText = await response.text();
              console.log('Fitbit token revoke failed:', errorText);
              return res.status(400).json({ message: 'Fitbit token revoke failed', success: false });
           }

            await supabase.from('fitbit_tokens').delete().eq('user_id', user.data.id);
            console.log('Fitbit access revoked and token deleted');

            return res.status(200).json({ message: 'Fitbit access revoked and token deleted', success: true });

        }catch(e){
          console.log()
          return res.status(400).json({message: 'there was an issue with trying to revoke the access token from fitbit api ', success: false})
        
        }
      
      
      }
    

      console.log('updateFitBitAccess: fitbitaccess bool has been successfully updated')
      return res.status(200).json({message: 'updateFitBitAccess: fitbitaccess bool has been successfully updated', success: true });
    

}

// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< Handle Fit Bit Callback >-----------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

// this route is a request to get an access token so we can get the fitbit data from the api 

// you need to fetch the users uuid from the users table here using an email query 
// This lets you associate the Fitbit token with the correct user record when storing it in the database

// also break this generated code down below and understand exactly what every part is doing/place comments before moving on 

export const handleFitBitCallback = async (req: Request, res: Response): Promise<void> => {
 const code = req.query.code as string;
 const email = req.query.state as string; // get the email from the url string to fetch the corro users uuid

  if (!code) {
    res.status(400).send('Missing authorization code.');
    return;
  }

  // Hardcoded credentials for testing fitbit api
  const clientId = process.env.FITBIT_CLIENT_ID;
  const clientSecret = process.env.FITBIT_CLIENT_SECRET;
  const redirectUri = 'https://ungelatinized-disharmoniously-lenora.ngrok-free.dev/api/fitBit/handleFitBitCallback';

    if (!clientId || !clientSecret) {
    res.status(500).send('Missing Fitbit credentials.');
    return;
  }

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64'); // creates a string url out of all the credentials


  try {
    // fetch the uuid for the corro user
   const { data: user, error } = await supabase
     .from('users')
     .select('id') // or 'uuid' if your column is named that
     .eq('email', email)
     .single();

     if (error || !user) {
       res.status(404).send('User not found.');
       return;
      }

       // fetches request to fitbit to get an access token and data
    const tokenResponse = await fetch('https://api.fitbit.com/oauth2/token', {
      method: 'POST',
      headers: {
        Authorization: `Basic ${credentials}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        client_id: clientId,
        grant_type: 'authorization_code',
        redirect_uri: redirectUri,
        code,
      }),
    });

    const tokenData = await tokenResponse.json();
    const tokenDataWithUuid = {
      ...tokenData,
     user_id: user.id // add the users uuid to the token so it can be matched
    }


// update the fitbit_tokens table in supabase with the access token credentials 

   const updateResult = await supabase
      .from('fitbit_tokens')
      .update({
        fitbit_user_id: tokenData.user_id,
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: new Date(Date.now() + tokenData.expires_in * 1000),
      })
      .eq('user_id', user.id)
      .select();

    if (!updateResult.data || updateResult.data.length === 0) {
      await supabase.from('fitbit_tokens').insert({
        user_id: user.id,
        fitbit_user_id: tokenData.user_id,
        access_token: tokenData.access_token,
        refresh_token: tokenData.refresh_token,
        expires_at: new Date(Date.now() + tokenData.expires_in * 1000),
      });
    }
   
    console.log('Fitbit token response:', tokenDataWithUuid);

    // if it succeeds redirect back to bioCue via deep link
    // make sure you info.plist is set up to receive deep links 
   res.redirect(`com.kieran.biocue://fitbit/success?email=${email}`);
  } catch (error) {
    console.error(' Token exchange failed:', error);
    res.status(500).json({message: 'Token exchange failed.', success: false});
  }
};


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< FETCH FITBIT DATA >--------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

// this will be the endpoint that userProvider fetchFitBitData() will hit

// match the users id with the stored access token (if they have one)
// check/fetch if the user has a valid access token and if it needs to be refreshed, if so refresh it
// use the valid access token to fetch the users fitbit api data and send it back to the front end 
// the front end will then store it in the user provider so langchain ahs access to it similar to the applekit process 


 interface FetchFitBitBody {
  email: string;
}

export const fetchFitBitData  = async (req: Request<{}, {}, FetchFitBitBody>, res: Response) => {

  const { email } = req.body;
 
  try{

     //fetch the id for the corro user
     const { data: user, error: userError } = await supabase.from('users').select('id').eq('email', email).single();


       if (userError || !user) {
         console.log('fetchFitBitData: error fetching user');
         return res.status(400).json({ message: 'User not found', success: false });
       }

    // now try to match that id with an access token in the fitbit_tokens table

       const userId = user.id;

       const { data: tokenRow, error: tokenError } = await supabase
        .from('fitbit_tokens')
        .select('*')
        .eq('user_id', userId)
        .single();

        if (tokenError || !tokenRow) {
         console.log('fetchFitBitData: error fetching token');
         return res.status(400).json({ message: 'Token not found', success: false });
       }
       
       // Check if token is expired
      const now = Date.now();
      const expiresAt = new Date(tokenRow.expires_at).getTime();

      let accessToken = tokenRow.access_token;

    if (now > expiresAt) {
      console.log('Token expired — refreshing');

      const clientId = process.env.FITBIT_CLIENT_ID;
      const clientSecret = process.env.FITBIT_CLIENT_SECRET;

      if (!clientId || !clientSecret) {
        res.status(500).send('Missing Fitbit credentials.');
        return;
      }


      const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

      const refreshResponse = await fetch('https://api.fitbit.com/oauth2/token', {
        method: 'POST',
        headers: {
          Authorization: `Basic ${credentials}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          grant_type: 'refresh_token',
          refresh_token: tokenRow.refresh_token, // get the refresh token data and sent it in the body
          client_id: clientId, // send the client id so fitbit knows which token its associated with
        }),
      });

      // --------< gives you the raw unparsed refresh response from fitbit for debugging purposes if the existing token fails >-----------

      const rawBody = await refreshResponse.text();
      console.log('Raw refresh response:', rawBody);

      if (rawBody.includes('invalid_grant')) {
        console.log('Refresh token is dead — user must reauth');

       // this will prompt the front end user to reAuth, get a new token and lock in again 
       // the auth code is in the grant access functionality for fitbit 
       // youll have to get a new token automatically if its 6+ hours old 
       //  just have a listener in the userProvider that gives the user a prompt to reconnect because their token is cooked ?
        return res.status(401).json({ message: 'Fitbit connection expired — please reconnect', needsReauth: true }); // this will prompt the front end user to reAuth, get a new token and lock in again 
      }     

      if (!refreshResponse.ok) {
        return res.status(400).json({ message: 'Token refresh failed', success: false });
      }

      const newTokenData = JSON.parse(rawBody);

      // Update Supabase with new token
      await supabase
        .from('fitbit_tokens')
        .update({
          access_token: newTokenData.access_token, // set the new access token data with the corro table for that user
          refresh_token: newTokenData.refresh_token, // same with refresh code 
          expires_at: new Date(Date.now() + newTokenData.expires_in * 1000), // create a new expiry time 
        })
        .eq('user_id', userId); // matching the users id with the access token in the supabase table 

      accessToken = newTokenData.access_token;

      if (!accessToken || accessToken === 'undefined') {
        console.log('fetchFitBitData: access token is missing or invalid');
         return res.status(400).json({ message: 'Access token is missing or invalid', success: false });
       }

    } // <----- (now > expiresAt ) Closing bracket 

    // now do the fitbit data fetch with the a valid access token 

       const headers = {
           Authorization: `Bearer ${accessToken}`,
        };

     const today = new Date().toISOString().split('T')[0]; // example:  "2025-11-17"

    const [sleepRes, activityRes, heartRes] = await Promise.all([
      fetch(`https://api.fitbit.com/1.2/user/-/sleep/date/${today}.json`, { headers }),
      fetch(`https://api.fitbit.com/1/user/-/activities/date/${today}.json`, { headers }),
      fetch(`https://api.fitbit.com/1/user/-/activities/heart/date/${today}/1d/1min.json`, { headers })
    ]);

      const sleepData = await sleepRes.json();
      const activityData = await activityRes.json();
      const heartRateData = await heartRes.json();

      res.status(200).json({
        sleep: sleepData,
        activity: activityData,
        heartRate: heartRateData,
        calories: activityData.summary?.caloriesOut ?? null,
        success: true,
      });



  }catch(e){
    console.log('fetchFitBitData: there was an issue with the fetch ')
    return res.status(400).json({ message: 'there was an issue with the fetch ', success: false });
  }
}