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
import { supabase } from './utils/supabaseClient';
import { PrismaClient } from '@prisma/client'
import userRoutes from './routes/userRoutes'; 
import restRoutes from './routes/restRoutes';
import appleHealthRoutes from './routes/appleHealthRoutes';
import fitBitRoutes from './routes/fitBitRoutes';


const app = express(); // Initialize Express


// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< TESTING ROUTE >-----------------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------


app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
}));

app.use(express.json()); // Parse JSON bodies

app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.originalUrl}`);
  next();
});

// route to use the user controller exported functions 
app.use('/api/users', userRoutes);
app.use('/api/rest', restRoutes);
app.use('/api/appleHealth', appleHealthRoutes);
app.use('/api/fitBit', fitBitRoutes)




async function testConnection() {
 const { data, error } = await supabase
  .from('ping_test')
  .select('*') // pulls every column (id, message, created_at, etc.) from every row — unless you add .limit(5) like you did, which restricts it to the first 5 rows.
  .limit(5);

  if (error) {
    console.error(' Supabase connection failed:', error.message);
  } else {
    console.log('Supabase connection successful. Sample data:', data);
  }
}

testConnection();

// Test route 
app.get('/', (req: Request, res: Response) => {
  res.send('TypeScript Express server is running!');
});

//  Start server
app.listen(3000, () => {
  console.log('Server listening on port 3000');
});









