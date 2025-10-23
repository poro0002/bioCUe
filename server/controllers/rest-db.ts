import express, { Request, Response } from 'express';

interface SuggestedChannels {
  [topic: string]: {
    [channelName: string]: string;
  };
}


export const suggestedChannels = async (req: Request, res: Response<SuggestedChannels>) => {
    
   const suggestedChannels: SuggestedChannels = {
     meditation: {
       lifeWithKyle: 'https://www.youtube.com/playlist?list=PLYKUhLTbTU8WHAQNNpP0zFdjb93bI2KBA',
       angeloDilullo: 'https://www.youtube.com/watch?v=FehLgFezZAI&list=PLR2bLIYLsk_QSZbsmETOqCAbknEfoSUaw',
       adyashanti: 'https://www.youtube.com/watch?v=lfDN2Go3arA&list=PLcOSpHSSrHb0FZb9xp7MofGWUv4OWU3AW',
       samHarris: 'https://www.youtube.com/watch?v=tw7XBKhZJh4&list=PLRSXPjY6egnmuqYz-9rAIe7VM4sUoDw-P',
       allyBoothroyd: 'https://www.youtube.com/watch?v=fmui0b1IbKk&list=PL19-3B-OVYod3o7TEAQxjy_T2Oqtqj3kb',
       bohoBeautiful: 'https://www.youtube.com/watch?v=FGO8IWiusJo&list=PLb09q0R7gAwQ_-PwFfNflJVzp8U9rAIwh',
       theMindfulMovement: 'https://www.youtube.com/watch?v=81wPysTTvm0&list=PLCQACBUblTbXjAbbUZxd-_PYmqSr9tCmF',
       
     },

     healing_lifestyle: {
        raelanAgle: 'https://www.youtube.com/@RaelanAgle',
        angeloDilullo: 'https://www.youtube.com/@SimplyAlwaysAwake',
        concioustv: 'https://www.youtube.com/@conscioustv',
        joeDispenza: 'https://www.youtube.com/@drjoedispenza/videos',
        lifeWithKyle: 'https://www.youtube.com/@life.withkyle',
        neelamSatsang: 'https://www.youtube.com/@NeelamSatsang/videos',
     },

     affirmations: {
            bosque: 'https://www.youtube.com/watch?v=1jvLv6AVOdY&list=PLvFDBkSYJa6qgXewzMUNgVtNRu4U1NrfG',
            lavendaire: 'https://www.youtube.com/watch?v=yo1pJ_D-H3M&list=PL37ErCJmMWd2uRFJBv19A2zC-oYmzvX25',
            jessicaHeslop: 'https://www.youtube.com/watch?v=gngnBMmqwDo&list=PLmIx2BhfDMowRgDOWDjbU8WVE2teRIT3p',
            mindBodySoul: 'https://www.youtube.com/watch?v=PPXQv8t7gY8&list=PLDrv1qSpibNUo59GZdaFkBprox82Y9eVN',
            drVanda: 'https://www.youtube.com/watch?v=3ieIVsX_wk4&list=PLlS51su3ax1-u8Rj4gxqA6JT_KjdhGgzR',
            breathInBreathOut: 'https://www.youtube.com/watch?v=n9o4plCaMj4&list=PLkfiy5VHw3deenq0qM1liW1soEYL08aLZ'
        },
      yoga: {
         jessicaRichburg: 'https://www.youtube.com/@JessicaRichburg',
         sanela: 'https://www.youtube.com/@sanelaosmanovicyoga',
         satvicYoga: 'https://www.youtube.com/@satvicyoga',
         charlieFollows: 'https://www.youtube.com/@CharlieFollows',
         kristynRoseYoga: 'https://www.youtube.com/@KristynRoseYoga',
         rosalieYoga: 'https://www.youtube.com/@RosalieYoga',
         aylaNova: 'https://www.youtube.com/@AylaNovaNidra',
     },
     whiteNoise: {
        relaxingWhiteNoise: 'https://www.youtube.com/@RelaxingWhiteNoise',
        rainSoundNatural: 'https://www.youtube.com/@RainSoundNatural2612',
        babyWhiteNoise: 'https://www.youtube.com/@BabyWhiteNoise-i8r',
        sleepWhiteNoise: 'https://www.youtube.com/@SleepWhiteNoise3',
        athenaIV: 'https://www.youtube.com/@athenaiv',
        againAlone: 'https://www.youtube.com/channel/UCOJ1abeT7F2YaBFxKoH_YHQ',
        shesGone: 'https://www.youtube.com/@shesgon3',
     }
    };

res.json(suggestedChannels);
   

};