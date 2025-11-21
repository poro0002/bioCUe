import express from 'express';
import { updateAppleHealthAccess } from '../controllers/appleHealthControllers';

const router = express.Router();

router.post('/updateAppleHealthAccess', updateAppleHealthAccess);

export default router;