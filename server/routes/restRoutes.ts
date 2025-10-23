import express from 'express';

import { suggestedChannels } from '../controllers/rest-db';

const router = express.Router();


router.get('/getSuggestedChannels', suggestedChannels);


export default router;