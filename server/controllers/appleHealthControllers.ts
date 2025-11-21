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
// --------------------------------------------------< UPDATE APPLE HEALTH ACCESS >-----------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

interface appleAccessBody{
  email: string;
  appleHealthAccess: boolean;
}


export const updateAppleHealthAccess = async(
  req: Request<{}, {}, appleAccessBody>, res: Response,
) =>{


   const {email, appleHealthAccess} = req.body;
   
   console.log('Incoming email:', email);


   const result = await supabase
  .from('users')
  .update({ applehealthaccess: appleHealthAccess }) // this prevents the camelCase mismatch that happens in supabase indexes
  .eq('email', email)
  .select(); 

console.log('Supabase update result:', result);


// there was an error trying to update the supabase boolean 
  if (result.error) {
    console.log('Error updating applehealthaccess:', result.error);
    return res.status(400).json({
      message: 'Error updating applehealthaccess',
      success: false,
    });
  }

  // the row that were looking for doesnt exist
  if (result.count === 0 || !result.data) {
    console.log('No rows matched for update');
    return res.status(404).json({
      message: 'No matching user found',
      success: false,
    });
  }

  // successful update to users data table 
  console.log('Successfully updated applehealthaccess for:', email);
  return res.status(200).json({
    message: 'Successfully updated applehealthaccess',
    success: true,
  });
}

