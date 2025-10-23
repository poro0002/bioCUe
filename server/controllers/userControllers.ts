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


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< DATA CONVERT FUNCTION  >-----------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------


// 1.  (obj: Record<string, any>) — this defines the type of the input parameter.
// 2.  : Record<string, any> — this defines the type of the return value.

const deepLowercaseKeys = (obj: Record<string, any>): Record<string, any> => {
  
  // “This is an object where every key is a string, and the value can be anything.”
  const result: Record<string, any> = {};

  for (const [key, value] of Object.entries(obj)) { // turn them into key value pairs 
    const lowerKey = key.toLowerCase();
    if (Array.isArray(value)) {
      result[lowerKey] = value; // If the value is an array (like ['citalophram']), we just copy it over.

    } else if (value !== null && typeof value === 'object') {
      result[lowerKey] = deepLowercaseKeys(value); // If the value is another object (like { agreeableness: 50 }), we recursively lowercase its keys too.
    } else {
      result[lowerKey] = value; //If it’s just a number, string, boolean, etc., we copy it over
    }
  }
  return result;
};


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< REGISTER ROUTE >-----------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

//schema for incoming data, has top be done in typescript 
interface RegisterBody {
  email: string;
  password: string;
  firstTimeLogin: boolean;
}

export const registerUser = async (
  req: Request<{}, {}, RegisterBody>,
  res: Response
) => {
    const { email, password, firstTimeLogin } = req.body
    
    try {
        // Check if email already exists
        // eq means equal
        // single mean return a row not an array

          const result = await supabase.from('users').select('email').eq('email', email).single()
          const existingUser = result.data
          const selectError = result.error
        
        // If user exists (no error), return conflict
        if (existingUser && !selectError) {
            return res.status(409).json({
                message: 'An account with this email already exists',
                success: false
            })
        }
        
        // Only proceed if error is "PGRST116" (no rows found)
        if (selectError && selectError.code !== 'PGRST116') {
            console.log('Database select error:', selectError)
            return res.status(400).json({
                message: 'Registration failed',
                success: false
            })
        }
        
        const hashedPassword = await bcrypt.hash(password, 10)
        
        const { error } = await supabase
            .from('users')
            .insert({
                email: email,
                password: hashedPassword,
                firsttimelogin: firstTimeLogin,
            })
        
        if (error) {
            console.log('Database insert error:', error)
            return res.status(400).json({
                message: 'Registration failed',
                success: false
            })
        }
        
        console.log('account created!')
        res.status(201).json({ message: 'new user created', success: true })
        
    } catch (e) {
        console.log('Registration error:', e)
        res.status(400).json({
            message: 'Registration failed',
            success: false
        })
    }
};


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< LOGIN ROUTE >--------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

interface LoginBody {
  email: string,
  password: string,
  
}

type SupabaseUser = {
  email: string;
  password: string;
  firstTimeLogin: boolean;
};

export const loginUser = async (
  req: Request<{}, {}, RegisterBody>,
  res: Response
) => {
    
    const {email, password} = req.body;

 

    try{
      const result = await supabase.from('users').select('email, password, firsttimelogin').eq('email', email).single();
       
      
 if (!result.data) {
      console.log('could not find user');
      return res.status(400).json({
        message: 'Could not find a user with that email',
        success: false,
      });
    }

    const existingUser = result.data; 
      
      const isPasswordCorrect = await bcrypt.compare(password, existingUser.password);

       if (!isPasswordCorrect) {
        console.log('password incorrect')
      return res.status(401).json({
        message: 'Incorrect password',
        success: false,
      });
    }
    console.log('successful login')

    return res.status(200).json({
      message: 'Login successful',
      success: true,
      user: {
        email: existingUser.email,
        firstTimeLogin: existingUser.firsttimelogin,
      },
    });





    }catch(e){
      console.log('issue logging in', e)
      return res.status(400).json({message: 'there was an issue with logging in', success: false})
    }
   


};




// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< CREATE GOOGLE USER ROUTE >--------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

// createGoogleUser route is creating a user in your manually made users table, using data sent from the frontend

interface GoogleUserBody {
  uuid: string;
  email: string;
  name?: string;
  age?: number;
  gender?: string;
  height?: number;
  weight?: number;
  diet?: string;
  selectedIllnesses?: string;
  allergies?: string;
  prescribedMedications?: string;
  neuroticism?: number;
  openness?: number;
  conscientiousness?: number;
  extraversion?: number;
  agreeableness?: number;
}

export const createGoogleUser = async (
  req: Request<{}, {}, GoogleUserBody>,
  res: Response
) => {
  const { uuid, email, ...userData } = req.body;
  
  try {
    // Check if user already exists
    const existingResult = await supabase
      .from('users')
      .select('uuid')
      .eq('email', email)
      .single();
    
    if (existingResult.data) {
      return res.status(409).json({
        message: 'User already exists',
        success: false
      });
    }
    
    // Create new user with Google OAuth UUID
    const snakePayload = deepLowercaseKeys({
      uuid,
      email,
      ...userData,
      firsttimelogin: false,
      isloggedin: true
    });
    
    const { error } = await supabase
      .from('users')
      .insert(snakePayload);
    
    if (error) {
      console.log('Database insert error:', error);
      return res.status(400).json({
        message: 'Failed to create user',
        success: false
      });
    }
    
    console.log('Google user created successfully');
    return res.status(201).json({ 
      message: 'User created', 
      success: true,
      email: email,
    });
    
  } catch (e) {
    console.log('Error creating Google user:', e);
    return res.status(500).json({
      message: 'Server error',
      success: false
    });
  }
};



// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< UPDATE USER DATA ROUTE >--------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

// userprofile data
interface UserProfileData {
  name: string;
  age: number;
  gender: string;
  height: number;
  weight: number;
  diet: string;
  selectedIllnesses: string;
  allergies: string;
  prescribedMedications: string;
  neuroticism: number;
  openness: number;
  conscientiousness: number;
  extraversion: number;
  agreeableness: number;
  isLoggedIn: boolean;
  firstTimeLogin: boolean;
  email: string;
}

export const updateUserData = async (
  req: Request<{}, {}, UserProfileData & { uuid?: string }>,
  res: Response
) => {

  const { uuid, ...userData } = req.body;
  const snakePayload = deepLowercaseKeys({ 
    ...userData, 
    firstTimeLogin: false 
  });
  
  // If uuid is provided (Google user), include it
  if (uuid) {
    snakePayload.uuid = uuid;
  }

  console.log('Payload to Supabase:', snakePayload);
  console.log('Updating user with email:', req.body.email);

  try {
    const result = await supabase
      .from('users')
      .upsert(snakePayload, { onConflict: 'email' }); // Use upsert to handle both insert and update

    if (result.error) {
      console.log('supabase update error:', result.error);
      return res.status(500).json({ message: 'Failed to update user data', success: false });
    }

    console.log('User data updated successfully');
    return res.status(200).json({ message: 'User data updated', success: true });
  } catch (e) {
    console.log('Server error:', e);
    return res.status(500).json({ message: 'Server error', success: false });
  }
};





// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< CHECK USER ROUTE >--------------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------
// Check if user exists in your custom users table
// asking backend: does this Supabase-authenticated user also exist in our custom app database?



//  •   Request<{}, {}, {}, { email?: string }> tells TypeScript:
//  ⁠◦   No URL params
//  ⁠◦   No request body
//  ⁠◦   No custom response body
//  ⁠◦   Query string includes optional email

export const checkUser = async (
  req: Request<{}, {}, {}, { email?: string }>,
  res: Response
) => {
  const email = req.query.email as string;

  console.log('Received /check-user request for:', email);
  
  try {
    const result = await supabase
      .from('users')
      .select('uuid, email, firsttimelogin')
      .eq('email', email)
      .single();

      if (!email) {
  return res.status(400).json({ error: 'Missing email query parameter' });
}
    
    if (result.error && result.error.code === 'PGRST116') {
      // User doesn't exist in custom table
      return res.json({ exists: false, firstTimeLogin: true });
    }
    
    if (result.error) {
      console.log('Error checking user:', result.error);
      return res.status(500).json({ error: 'Server error' });
    }
    
    return res.json({ 
      exists: true, 
      firstTimeLogin: result.data.firsttimelogin, // even if there is an account found, have they completed the onboarding questions ?
      uuid: result.data.uuid
    });
  } catch (error) {
    console.error('Error checking user:', error);
    return res.status(500).json({ error: 'Server error' });
  }
};

