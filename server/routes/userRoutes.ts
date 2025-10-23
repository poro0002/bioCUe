import express from 'express';
import { registerUser, loginUser, createGoogleUser, updateUserData, checkUser} from '../controllers/userControllers';

const router = express.Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/create-google-user', createGoogleUser); ///create-google-user route is not automatically called by Supabase. 
router.post('/updateUserData', updateUserData);
router.get('/check-user', checkUser);

export default router;