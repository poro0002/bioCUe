import express from 'express';
import { updateFitBitAccess, handleFitBitCallback, fetchFitBitData } from '../controllers/fitBitControllers';

const router = express.Router();

router.post('/updateFitBitAccess', updateFitBitAccess);
router.get('/handleFitBitCallback', handleFitBitCallback);
router.post('/fetchFitBitData', fetchFitBitData);

export default router;