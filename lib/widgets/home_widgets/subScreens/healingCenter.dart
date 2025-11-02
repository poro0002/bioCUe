// this widget will contain meditations, breathwork, affirmations, yoga, white noise ambience
// use a topic keyword and fetch random videos and display them as thumbnail links in carousel for each topic (include the title and duration under the thumbnail of each)
// under them in the same topic will be channel suggestions with elevated buttons that source urls from the supabase table "suggested channels"
//

// on mount the app needs to fetch the suggested channels
// on mount it also has to use the youtube api to fetch video with the corro keyword for each category
// inside the state class, there will be child widgets (each topic category (meditation, asmr, ect.))
// make sure to pass the props to these childs as well (they are stateless widgets )

// state class will have all the links that have been fetched for that topic so it can loop through and create embedded links with the title and duration
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../env.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config.dart';

class HealingCenter extends StatefulWidget {
  const HealingCenter({super.key});

  @override
  State<HealingCenter> createState() => _HealingCenterState();
}

// ---------------------------------------------------------------------------------------------------
// -------------------------------< VideoData/ChannelData model/Schema class with constructor >--------------------
// ---------------------------------------------------------------------------------------------------

//
// this holds all the data that comes back from each fetch
// its basically a schema to set the data

class VideoData {
  final String title;
  final String thumbnailUrl;
  final String videoId;
  final String duration;
  final String videoUrl;

  VideoData({
    required this.title,
    required this.thumbnailUrl,
    required this.videoId,
    required this.duration,
    required this.videoUrl,
  });
}

// channelData model class with constructor
class ChannelData {
  final String name;
  final String url;

  ChannelData({required this.name, required this.url});
}

// ---------------------------------------------------------------------------------------------------
// -------------------------------< Fetch Videos Function >---------------------------------------------
// ---------------------------------------------------------------------------------------------------

Future<List<VideoData>> fetchYouTubeVideos(String topic) async {
  final apiKey = Env.youtubeApiKey;
  final url = Uri.parse(
    // all the queries and url
    'https://www.googleapis.com/youtube/v3/search'
    '?part=snippet'
    '&q=$topic'
    '&type=video'
    '&maxResults=10'
    '&key=$apiKey',
  );

  // this is what flutter gets back from the youtube API fetch
  // and you're using snippet because it has the tittle and url . basically the vital info in the obj
  // {
  //   "kind": "youtube#searchListResponse",
  //   "etag": "...",
  //   "items": [
  //     {
  //       "id": { "videoId": "abc123" },
  //       "snippet": { "title": "Relaxing Meditation", url: ... }
  //     },
  //     {
  //       "id": { "videoId": "def456" },
  //       "snippet": { "title": "Deep Breathing", url: ... }
  //     }
  //   ]
  // }

  final response = await http.get(url); // place the parsed url

  if (response.statusCode != 200) {
    print("YouTube API error: ${response.statusCode}");
    return []; // there is an issue return a empty array as base case
  }

  final data = json.decode(
    response.body,
  ); // get the data from the response and put it in a var
  final items =
      data['items'] ??
      []; // items has the vital info && base case just in case it isnt there

  return items.map<VideoData>((item) {
    // take each item in the list and transform it into a VideoData object. you’re telling Dart what type you want the output to be
    final snippet = item['snippet'];
    return VideoData(
      // now set all the corro data for what it should be
      title: snippet['title'] ?? 'Untitled',
      thumbnailUrl: snippet['thumbnails']['default']['url'] ?? '',
      videoId: item['id']['videoId'] ?? '',
      duration: '', // Skipped
      videoUrl: 'https://www.youtube.com/watch?v=${item['id']['videoId']}',
    );
  }).toList(); // it turns an Iterable of objects built from your schema into a Dart List.(array)
}

// ---------------------------------------------------------------------------------------------------
// -------------------------------< Fetch Suggested Channels Function >-------------------------------
// ---------------------------------------------------------------------------------------------------

Future<List<ChannelData>> fetchSuggestedChannels(String topic) async {
  final uri = Uri.parse(
    '${AppConfig.backendBaseUrl}/api/rest/getSuggestedChannels', // error 404 fetching from channels
  );

  final response = await http.get(uri);

  if (response.statusCode != 200) {
    print('Error fetching suggested channels: ${response.statusCode}');
    return [];
  }

  final data = json.decode(response.body);

  final topicData = data[topic];
  if (topicData == null) return [];

  return topicData.entries.map<ChannelData>((entry) {
    // topicData.entries gives you a list of key-value pairs: [MapEntry("lifeWithKyle", "https://..."), MapEntry("samHarris", "https://...")]
    return ChannelData(
      name: entry.key,
      url: entry.value,
    ); // sets each in the correct spot for the schema
  }).toList(); // turn it back into a array/list
}

// -------------------------------------------------------------------------------
// -------------------------------< State Class >---------------------------------
// -------------------------------------------------------------------------------

class _HealingCenterState extends State<HealingCenter> {
  final apiKey = Env.youtubeApiKey;
  List<VideoData> meditationVideos = [];
  List<ChannelData> meditationChannels = [];

  @override
  void initState() {
    super.initState();
    loadAllTopics();
  }

  final List<String> topics = [
    'meditation',
    'yoga',
    'affirmations',
    'healing_lifestyle',
    'whiteNoise',
  ];

  // fetchYouTubeVideos && fetchSuggestedChannels all get ran for each topic and all that data gets compiled into the variables below

  // it ends up looking like this
  // topicVideos =
  //{
  //   "meditation": [
  //     VideoData(title: "Relaxing Meditation", thumbnailUrl: "...", videoId: "abc123", duration: ""),
  //     VideoData(title: "Deep Breathing", thumbnailUrl: "...", videoId: "def456", duration: ""),
  //   ],
  //   "yoga": [
  //     VideoData(title: "Morning Yoga Flow", thumbnailUrl: "...", videoId: "xyz789", duration: ""),
  //   ],
  //   "asmr": [
  //     VideoData(title: "ASMR Sleep Sounds", thumbnailUrl: "...", videoId: "zzz111", duration: ""),
  //   ],
  // }

  final Map<String, List<VideoData>> topicVideos = {};
  final Map<String, List<ChannelData>> topicChannels = {};

  // ----------------------------------------------------------------------
  // ----------------------< Load All Topics Function >--------------------
  // ----------------------------------------------------------------------

  Future<void> loadAllTopics() async {
    for (final topic in topics) {
      // loops through all the topics and does a fetch for each
      final videos = await fetchYouTubeVideos(topic);
      final channels = await fetchSuggestedChannels(topic);

      setState(() {
        // dynamically sets each  and has an object that holds all
        topicVideos[topic] = videos;
        topicChannels[topic] = channels;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Healing Center")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TopicSection(
              title: "Meditation",
              icon: Icons.self_improvement,
              videos: topicVideos["meditation"] ?? [],
              channels: topicChannels["meditation"] ?? [],
            ),
            TopicSection(
              title: "Affirmations",
              icon: Icons.auto_awesome,
              videos: topicVideos["affirmations"] ?? [],
              channels: topicChannels["affirmations"] ?? [],
            ),
            TopicSection(
              title: "Yoga",
              icon: Icons.accessibility_new,
              videos: topicVideos["yoga"] ?? [],
              channels: topicChannels["yoga"] ?? [],
            ),
            TopicSection(
              title: "White noise",
              icon: Icons.surround_sound,
              videos: topicVideos["whiteNoise"] ?? [],
              channels: topicChannels["whiteNoise"] ?? [],
            ),
            TopicSection(
              title: "Healing lifestyle",
              icon: Icons.spa,
              videos: topicVideos["healing_lifestyle"] ?? [],
              channels: topicChannels["healing_lifestyle"] ?? [],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------------------------------------------------------------
// --------------------------------------------------< Topic Section Child Widget  >------------------------------------------
// -------------------------------------------------------------------------------------------------------------------------

// takes three props passed down from state class
class TopicSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<VideoData> videos;
  final List<ChannelData> channels;

  const TopicSection({
    required this.title,
    required this.icon,
    required this.videos,
    required this.channels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFFFF6F61), size: 24),
            SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Container(
                width: 120, //
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (video.videoUrl.isEmpty) {
                          print('No video URL available');
                          return;
                        }

                        final uri = Uri.parse(video.videoUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          print("Could not launch ${video.videoUrl}");
                        }
                      },
                      child: Image.network(
                        video.thumbnailUrl,
                        width: 120,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Text(
                      video.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Wrap(
          spacing: 8,
          children: channels.map((channel) {
            return ElevatedButton(
              // this will take yopu to the suggested channels below the carousel of videos
              onPressed: () async {
                final uri = Uri.parse(channel.url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  // Optional: show error
                  print("Could not launch ${channel.url}");
                }
              },
              child: Text(channel.name),
            );
          }).toList(),
        ),
        SizedBox(height: 24),
      ],
    );
  }
}
