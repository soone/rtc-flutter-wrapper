import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:handy_toast/handy_toast.dart';
import 'package:rongcloud_rtc_wrapper_plugin/rongcloud_rtc_wrapper_plugin.dart';
import 'package:rongcloud_rtc_wrapper_plugin_example/frame/template/mvp/view.dart';
import 'package:rongcloud_rtc_wrapper_plugin_example/frame/ui/loading.dart';
import 'package:rongcloud_rtc_wrapper_plugin_example/frame/utils/extension.dart';
import 'package:rongcloud_rtc_wrapper_plugin_example/utils/utils.dart';
import 'package:rongcloud_rtc_wrapper_plugin_example/widgets/ui.dart';

import 'audience_page_contract.dart';
import 'audience_page_presenter.dart';

class AudiencePage extends AbstractView {
  @override
  _AudiencePageState createState() => _AudiencePageState();
}

class _AudiencePageState extends AbstractViewState<AudiencePagePresenter, AudiencePage> implements View, RCRTCStatsListener {
  @override
  AudiencePagePresenter createPresenter() {
    return AudiencePagePresenter();
  }

  @override
  void init(BuildContext context) {
    super.init(context);

    _roomId = ModalRoute.of(context)?.settings.arguments as String;

    Utils.engine?.setStatsListener(this);
    Utils.onRemoveUserAudio = (id) {
      _remoteUserAudioStateSetter?.call(() {
        _remoteUserAudioState.remove(id);
      });
    };
    Utils.engine?.onRemoteLiveMixUnpublished = (type) {
      if (mounted) {
        setState(() {
          switch (type) {
            case RCRTCMediaType.video:
              _muteVideo = false;
              break;
            case RCRTCMediaType.audio:
              _muteAudio = false;
              break;
            case RCRTCMediaType.audio_video:
              _muteAudio = false;
              _muteVideo = false;
              break;
          }
        });
      }
    };
  }

  @override
  void dispose() {
    _remoteAudioStatsStateSetter = null;
    _remoteVideoStatsStateSetter = null;
    _remoteUserAudioStateSetter = null;
    _remoteAudioStats = null;
    _remoteVideoStats = null;
    _remoteUserAudioState.clear();
    super.dispose();
  }

  @override
  Widget buildWidget(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text('观看直播'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.message,
              ),
              onPressed: () => _showMessagePanel(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Row(
              children: [
                Spacer(),
                Radios(
                  '音频',
                  value: RCRTCMediaType.audio,
                  groupValue: _type,
                  onChanged: (dynamic value) {
                    setState(() {
                      _type = value;
                    });
                  },
                ),
                Spacer(),
                Radios(
                  '视频',
                  value: RCRTCMediaType.video,
                  groupValue: _type,
                  onChanged: (dynamic value) {
                    setState(() {
                      _type = value;
                    });
                  },
                ),
                Spacer(),
                Radios(
                  '音视频',
                  value: RCRTCMediaType.audio_video,
                  groupValue: _type,
                  onChanged: (dynamic value) {
                    setState(() {
                      _type = value;
                    });
                  },
                ),
                Spacer(),
              ],
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            _type != RCRTCMediaType.audio
                ? Row(
                    children: [
                      Spacer(),
                      CheckBoxes(
                        '订阅小流',
                        checked: _tiny,
                        onChanged: (checked) {
                          setState(() {
                            _tiny = checked;
                          });
                        },
                      ),
                      Spacer(),
                    ],
                  )
                : Container(),
            _type != RCRTCMediaType.audio
                ? Divider(
                    height: 15.dp,
                    color: Colors.transparent,
                  )
                : Container(),
            Row(
              children: [
                Spacer(),
                Button(
                  '订阅',
                  callback: () => _refresh(),
                ),
                Spacer(),
              ],
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(
                color: Colors.blue,
                child: Stack(
                  children: [
                    _host ?? Container(),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: 5.dp,
                          top: 5.dp,
                        ),
                        child: BoxFitChooser(
                          fit: _host?.fit ?? BoxFit.cover,
                          onSelected: (fit) {
                            setState(() {
                              _host?.fit = fit;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            Row(
              children: [
                Spacer(),
                CheckBoxes(
                  '静音视频',
                  checked: _muteVideo,
                  onChanged: (checked) {
                    _muteVideoStream();
                  },
                ),
                Spacer(),
                CheckBoxes(
                  '静音音频',
                  checked: _muteAudio,
                  onChanged: (checked) {
                    _muteAudioStream();
                  },
                ),
                Spacer(),
              ],
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            Row(
              children: [
                Spacer(),
                Button(
                  _speaker ? '扬声器' : '听筒',
                  size: 15.sp,
                  callback: () => _changeSpeaker(),
                ),
                Spacer(),
              ],
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            Row(
              children: [
                Spacer(),
                Button(
                  'Reset View',
                  size: 15.sp,
                  callback: () => _resetView(),
                ),
                Spacer(),
              ],
            ),
            Divider(
              height: 5.dp,
              color: Colors.transparent,
            ),
            StatefulBuilder(builder: (context, setter) {
              _remoteAudioStatsStateSetter = setter;
              return RemoteAudioStatsTable(_remoteAudioStats);
            }),
            StatefulBuilder(builder: (context, setter) {
              _remoteVideoStatsStateSetter = setter;
              return RemoteVideoStatsTable(_remoteVideoStats);
            }),
            StatefulBuilder(builder: (context, setter) {
              _remoteUserAudioStateSetter = setter;
              return Expanded(
                child: ListView.separated(
                  itemCount: _remoteUserAudioState.keys.length,
                  separatorBuilder: (context, index) {
                    return Divider(
                      height: 5.dp,
                      color: Colors.transparent,
                    );
                  },
                  itemBuilder: (context, index) {
                    String userId = _remoteUserAudioState.keys.elementAt(index);
                    int volume = _remoteUserAudioState[userId] ?? 0;
                    return Row(
                      children: [
                        Spacer(),
                        userId.toText(),
                        VerticalDivider(
                          width: 10.dp,
                          color: Colors.transparent,
                        ),
                        '$volume'.toText(),
                        Spacer(),
                      ],
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
      onWillPop: _exit,
    );
  }

  void _showMessagePanel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return MessagePanel(_roomId, false);
      },
    );
  }

  void _refresh() async {
    Loading.show(context);
    if (_type == RCRTCMediaType.audio) {
      _host = null;
      await Utils.engine?.removeLiveMixView();
    } else {
      _host = await RCRTCView.create(
        mirror: false,
        onFirstFrameRendered: () {
          print('AudiencePage onFirstFrameRendered');
        },
      );
      if (_host != null) {
        await Utils.engine?.setLiveMixView(_host!);
      }
    }
    presenter.subscribe(_type, _tiny);
    setState(() {});
  }

  void _muteAudioStream() async {
    bool result = await presenter.mute(RCRTCMediaType.audio, !_muteAudio);
    setState(() {
      _muteAudio = result;
    });
  }

  void _muteVideoStream() async {
    bool result = await presenter.mute(RCRTCMediaType.video, !_muteVideo);
    setState(() {
      _muteVideo = result;
    });
  }

  void _changeSpeaker() async {
    bool result = await presenter.changeSpeaker(!_speaker);
    setState(() {
      _speaker = result;
    });
  }

  void _resetView() async {
    BoxFit? fit = _host?.fit;
    bool? mirror = _host?.mirror;
    _host = null;
    await Utils.engine?.removeLiveMixView();
    _host = await RCRTCView.create(
      fit: fit ?? BoxFit.contain,
      mirror: mirror ?? false,
    );
    if (_host != null) await Utils.engine?.setLiveMixView(_host!);
    setState(() {});
  }

  Future<bool> _exit() async {
    Loading.show(context);
    await Utils.engine?.setStatsListener(null);
    await presenter.exit();
    Loading.dismiss(context);
    Navigator.pop(context);
    return Future.value(false);
  }

  @override
  void onConnected() {
    Loading.dismiss(context);
    'Subscribe success!'.toast();
  }

  @override
  void onConnectError(int? code, String? message) {
    Loading.dismiss(context);
    'Subscribe error, code = $code, message = $message'.toast();
  }

  @override
  void onNetworkStats(RCRTCNetworkStats stats) {}

  @override
  void onLocalAudioStats(RCRTCLocalAudioStats stats) {}

  @override
  void onLocalVideoStats(RCRTCLocalVideoStats stats) {}

  @override
  void onRemoteAudioStats(String roomId, String userId, RCRTCRemoteAudioStats stats) {}

  @override
  void onRemoteVideoStats(String roomId, String userId, RCRTCRemoteVideoStats stats) {}

  @override
  void onLiveMixAudioStats(RCRTCRemoteAudioStats stats) {
    _remoteAudioStatsStateSetter?.call(() {
      _remoteAudioStats = stats;
    });
  }

  @override
  void onLiveMixVideoStats(RCRTCRemoteVideoStats stats) {
    _remoteVideoStatsStateSetter?.call(() {
      _remoteVideoStats = stats;
    });
  }

  @override
  void onLiveMixMemberAudioStats(String userId, int volume) {
    _remoteUserAudioStateSetter?.call(() {
      _remoteUserAudioState[userId] = volume;
    });
  }

  @override
  void onLiveMixMemberCustomAudioStats(String userId, String tag, int volume) {
    _remoteUserAudioStateSetter?.call(() {
      _remoteUserAudioState['$userId@$tag'] = volume;
    });
  }

  @override
  void onLocalCustomAudioStats(String tag, RCRTCLocalAudioStats stats) {}

  @override
  void onLocalCustomVideoStats(String tag, RCRTCLocalVideoStats stats) {}

  @override
  void onRemoteCustomAudioStats(String roomId, String userId, String tag, RCRTCRemoteAudioStats stats) {}

  @override
  void onRemoteCustomVideoStats(String roomId, String userId, String tag, RCRTCRemoteVideoStats stats) {}

  late String _roomId;
  RCRTCView? _host;
  RCRTCMediaType _type = RCRTCMediaType.audio_video;
  bool _tiny = false;
  bool _speaker = false;

  StateSetter? _remoteAudioStatsStateSetter;
  StateSetter? _remoteVideoStatsStateSetter;
  StateSetter? _remoteUserAudioStateSetter;

  RCRTCRemoteAudioStats? _remoteAudioStats;
  RCRTCRemoteVideoStats? _remoteVideoStats;
  Map<String, int> _remoteUserAudioState = {};

  bool _muteAudio = false;
  bool _muteVideo = false;
}
