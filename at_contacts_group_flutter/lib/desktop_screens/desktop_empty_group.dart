import 'package:at_contact/at_contact.dart';
import 'package:at_contacts_flutter/utils/colors.dart';
import 'package:at_contacts_group_flutter/services/group_service.dart';
import 'package:at_contacts_group_flutter/services/navigation_service.dart';
import 'package:at_contacts_group_flutter/utils/images.dart';
import 'package:at_contacts_group_flutter/desktop_routes/desktop_route_names.dart';
import 'package:at_contacts_group_flutter/desktop_routes/desktop_routes.dart';
import 'package:at_contacts_group_flutter/utils/text_constants.dart';
import 'package:at_contacts_group_flutter/utils/text_styles.dart';
import 'package:at_contacts_group_flutter/widgets/error_screen.dart';
import 'package:flutter/material.dart';
import 'package:at_common_flutter/services/size_config.dart';

/// TODO:
/// Duplicate GlobalKey detected in widget tree as we now have
/// select contacts on right side and left side we have empty widget
/// and empty widget inturn has nested widgets, so it thriws error

class DesktopEmptyGroup extends StatefulWidget {
  @override
  _DesktopEmptyGroupState createState() => _DesktopEmptyGroupState();
}

class _DesktopEmptyGroupState extends State<DesktopEmptyGroup> {
  bool createBtnTapped = false;
  List<AtContact?> selectedContactList = [];
  bool showAddGroupIcon = false, errorOcurred = false;

  @override
  void initState() {
    try {
      super.initState();
      GroupService().getAllGroupsDetails();
      GroupService().atGroupStream.listen((groupList) {
        if (groupList.isNotEmpty) {
          showAddGroupIcon = true;
        } else {
          showAddGroupIcon = false;
        }
        if (mounted) setState(() {});
      });
    } catch (e) {
      print('Error in init of Group_list $e');
      if (mounted) {
        setState(() {
          errorOcurred = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Container(
      width: SizeConfig().screenWidth - TextConstants.SIDEBAR_WIDTH,
      color: Color(0xFFF7F7FF),
      child: StreamBuilder(
        stream: GroupService().atGroupStream,
        builder: (BuildContext context, AsyncSnapshot<List<AtGroup>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasError) {
              return ErrorScreen(onPressed: () {
                GroupService().getAllGroupsDetails();
              });
            } else {
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty) {
                  showAddGroupIcon = false;
                  return createBtnTapped ? nested_navigators() : _emptyGroup();
                } else {
                  return nested_navigators();
                }
              } else {
                return _emptyGroup();
              }
            }
          }
        },
      ),
    );
  }

  Widget nested_navigators() {
    return SizedBox(
      width: SizeConfig().screenWidth - TextConstants.SIDEBAR_WIDTH,
      child: Row(
        children: [
          Expanded(
            child: Navigator(
              key: NavService.groupPckgLeftHalfNavKey,
              initialRoute: DesktopRoutes.DESKTOP_GROUP_LEFT_INITIAL,
              onGenerateRoute: (routeSettings) {
                var routeBuilders = DesktopSetupRoutes.groupLeftRouteBuilders(
                    context, routeSettings);
                return MaterialPageRoute(builder: (context) {
                  return routeBuilders[routeSettings.name]!(context);
                });
              },
            ),
          ),
          Expanded(
            child: Navigator(
              key: NavService.groupPckgRightHalfNavKey,
              initialRoute: DesktopRoutes.DESKTOP_GROUP_RIGHT_INITIAL,
              onGenerateRoute: (routeSettings) {
                var routeBuilders = DesktopSetupRoutes.groupRightRouteBuilders(
                  context,
                  routeSettings,
                  initialRouteOnArrowBackTap: () {
                    setState(() {
                      createBtnTapped = false;
                    });
                  },
                  initialRouteOnDoneTap:
                      _navigator(DesktopRoutes.DESKTOP_NEW_GROUP),
                );
                return MaterialPageRoute(builder: (context) {
                  return routeBuilders[routeSettings.name]!(context);
                });
              },
            ),
          )
        ],
      ),
    );
  }

  _navigator(String _route) {
    switch (_route) {
      case DesktopRoutes.DESKTOP_GROUP_RIGHT_INITIAL:
        return () {
          Navigator.of(NavService.groupPckgRightHalfNavKey.currentContext!)
              .pushNamed(DesktopRoutes.DESKTOP_GROUP_RIGHT_INITIAL);
        };
      case DesktopRoutes.DESKTOP_GROUP_LIST:
        return () {
          Navigator.of(NavService.groupPckgLeftHalfNavKey.currentContext!)
              .pushReplacementNamed(DesktopRoutes.DESKTOP_GROUP_LIST,
                  arguments: {
                'onDone': _navigator(DesktopRoutes.DESKTOP_GROUP_RIGHT_INITIAL),
              });
        };
      case DesktopRoutes.DESKTOP_GROUP_DETAIL:
        return () {
          Navigator.of(NavService.groupPckgRightHalfNavKey.currentContext!)
              .pushReplacementNamed(DesktopRoutes.DESKTOP_GROUP_DETAIL,
                  arguments: {});
        };

      case DesktopRoutes.DESKTOP_NEW_GROUP:
        return () {
          Navigator.of(NavService.groupPckgRightHalfNavKey.currentContext!)
              .pushNamed(DesktopRoutes.DESKTOP_NEW_GROUP, arguments: {
            'onPop': () {
              Navigator.of(NavService.groupPckgRightHalfNavKey.currentContext!)
                  .pop();
            },
            'onDone': () {
              Navigator.of(NavService.groupPckgLeftHalfNavKey.currentContext!)
                  .pushReplacementNamed(DesktopRoutes.DESKTOP_GROUP_LIST,
                      arguments: {
                    'onDone':
                        _navigator(DesktopRoutes.DESKTOP_GROUP_RIGHT_INITIAL),
                  });
              Navigator.of(NavService.groupPckgRightHalfNavKey.currentContext!)
                  .pushReplacementNamed(DesktopRoutes.DESKTOP_GROUP_DETAIL,
                      arguments: {});
            }
          });
        };
    }
  }

  Widget _emptyGroup() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          AllImages().EMPTY_GROUP,
          width: 181.toWidth,
          height: 181.toWidth,
          fit: BoxFit.cover,
          package: 'at_contacts_group_flutter',
        ),
        SizedBox(
          height: 15.toHeight,
        ),
        Text('No Groups!', style: CustomTextStyles().grey16),
        SizedBox(
          height: 5.toHeight,
        ),
        Text(
          'Would you like to create a group?',
          style: CustomTextStyles().grey16,
        ),
        SizedBox(
          height: 20.toHeight,
        ),
        TextButton(
          onPressed: () {
            setState(() {
              createBtnTapped = true;
            });
          },
          style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              return ColorConstants.orangeColor;
            },
          ), fixedSize: MaterialStateProperty.resolveWith<Size>(
            (Set<MaterialState> states) {
              return Size(160, 45);
            },
          )),
          child: Text(
            'Create',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
      ],
    );
  }
}

// Container(
//             width: SizeConfig().screenWidth / 2 - 35,
//             child: DesktopNewGroup(),
//           )
