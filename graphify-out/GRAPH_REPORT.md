# Graph Report - wardly  (2026-05-14)

## Corpus Check
- 100 files · ~72,888 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 951 nodes · 1284 edges · 74 communities (68 shown, 6 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `55c524c0`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 42 edges
2. `../utils/app_theme.dart` - 36 edges
3. `package:google_fonts/google_fonts.dart` - 33 edges
4. `package:cloud_firestore/cloud_firestore.dart` - 22 edges
5. `package:provider/provider.dart` - 22 edges
6. `../providers/auth_provider.dart` - 16 edges
7. `package:flutter/foundation.dart` - 14 edges
8. `../utils/app_constants.dart` - 14 edges
9. `Wardly — Project Context for Claude` - 13 edges
10. `../models/app_user.dart` - 12 edges

## Surprising Connections (you probably didn't know these)
- `main()` --calls--> `my_application_new()`  [INFERRED]
  linux/runner/main.cc → linux/runner/my_application.cc
- `my_application_activate()` --calls--> `fl_register_plugins()`  [INFERRED]
  linux/runner/my_application.cc → linux/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `SetChildContent()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp

## Communities (74 total, 6 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (44): ../models/note_comment.dart, ../models/note.dart, note_comments_sheet.dart, package:timeago/timeago.dart, ../services/note_service.dart, cancelSubscriptions, dispose, NoteProvider (+36 more)

### Community 1 - "Community 1"
Cohesion: 0.11
Nodes (43): app_frame(), darken(), draw_appbar_title(), draw_bottom_nav(), draw_brand_header(), draw_emoji(), emoji_font(), find_emoji_font() (+35 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (36): ../models/app_user.dart, ../screens/admin/add_ward_screen.dart, ../screens/admin/admin_staff_screen.dart, ../screens/admin/ward_detail_screen.dart, ../screens/auth/background_setup_screen.dart, ../screens/auth/login_screen.dart, ../screens/auth/onboarding_screen.dart, ../screens/auth/splash_screen.dart (+28 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (36): _ackedNoteMock, AnimatedContainer, _back, _BenefitTile, build, Column, Container, dispose (+28 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (35): ../auth/background_setup_screen.dart, help_screen.dart, package:package_info_plus/package_info_plus.dart, ../../providers/text_scale_provider.dart, _aboutCard, _accountCard, build, _cardWrapper (+27 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (33): ../../models/models.dart, package:uuid/uuid.dart, ../../providers/ward_provider.dart, AddWardScreen, _AddWardScreenState, build, dispose, Scaffold (+25 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (33): package:android_intent_plus/android_intent.dart, package:app_settings/app_settings.dart, package:device_info_plus/device_info_plus.dart, package:permission_handler/permission_handler.dart, BackgroundSetupScreen, _BackgroundSetupScreenState, _batteryStep, build (+25 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (30): background_setup_screen.dart, onboarding_screen.dart, package:flutter_animate/flutter_animate.dart, ../../services/push_service.dart, build, Container, dispose, Expanded (+22 more)

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (29): ../admin/admin_home_screen.dart, ../admin/admin_staff_screen.dart, ../doctor/add_note_screen.dart, ../doctor/doctor_home_screen.dart, ../doctor/patients_list_screen.dart, ../nurse/nurse_home_screen.dart, ../nurse/nurse_patients_screen.dart, package:showcaseview/showcaseview.dart (+21 more)

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (25): patients_list_screen.dart, ../shared/filtered_notes_screen.dart, build, _buildHeader, _buildNotesList, _buildPatientsRow, _buildStats, Column (+17 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (24): add_ward_screen.dart, AdminHomeScreen, _AdminHomeScreenState, build, Column, Container, _header, initState (+16 more)

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (24): _alertBanner, _allNotesHeader, _allNotesList, build, Column, Container, _header, Icon (+16 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (23): add_patient_screen.dart, patient_detail_screen.dart, build, Center, Column, Container, dispose, _highlightText (+15 more)

### Community 14 - "Community 14"
Cohesion: 0.1
Nodes (21): batch, cascadeDeleteWard(), COMMON_OPTS, db, dead, { defineSecret }, email, filtered (+13 more)

### Community 15 - "Community 15"
Cohesion: 0.09
Nodes (21): dart:math, package:flutter/services.dart, ../../services/metrics_service.dart, build, Center, Container, Divider, Exception (+13 more)

### Community 16 - "Community 16"
Cohesion: 0.09
Nodes (21): Android Signing, App Store (iOS) — TODO, Config, Design System, graphify, Important File Locations, iOS Signing, Key Architecture Decisions (+13 more)

### Community 17 - "Community 17"
Cohesion: 0.1
Nodes (19): build, Center, _chip, Container, dispose, _infoCard, initState, InputDecoration (+11 more)

### Community 18 - "Community 18"
Cohesion: 0.1
Nodes (19): add_note_screen.dart, build, Center, Container, DateFormat, _dateHeader, dispose, Divider (+11 more)

### Community 19 - "Community 19"
Cohesion: 0.15
Nodes (14): app, checkAuth(), checkFirestore(), db, firebaseConfig, loadCounters(), loadFeed(), runAll() (+6 more)

### Community 20 - "Community 20"
Cohesion: 0.12
Nodes (15): add_staff_bottom_sheet.dart, AdminStaffScreen, _AdminStaffScreenState, build, Center, dispose, _filterChips, InkWell (+7 more)

### Community 21 - "Community 21"
Cohesion: 0.12
Nodes (15): AddPatientScreen, _AddPatientScreenState, build, dispose, initState, InkWell, _label, Scaffold (+7 more)

### Community 22 - "Community 22"
Cohesion: 0.12
Nodes (15): AnimatedContainer, _back, build, _navBar, _next, Padding, Scaffold, SingleChildScrollView (+7 more)

### Community 23 - "Community 23"
Cohesion: 0.13
Nodes (14): nurse_patient_detail_screen.dart, ../../providers/patient_provider.dart, build, Column, dispose, EmptyState, NursePatientsScreen, _NursePatientsScreenState (+6 more)

### Community 24 - "Community 24"
Cohesion: 0.13
Nodes (14): acknowledge_sheet.dart, build, Center, _chip, Container, Divider, Expanded, _infoCard (+6 more)

### Community 25 - "Community 25"
Cohesion: 0.13
Nodes (14): build, Center, ClipRRect, Container, Divider, DraggableScrollableSheet, _emptyState, NotificationsPanel (+6 more)

### Community 26 - "Community 26"
Cohesion: 0.14
Nodes (4): fl_register_plugins(), main(), my_application_activate(), my_application_new()

### Community 27 - "Community 27"
Cohesion: 0.18
Nodes (9): package:firebase_core/firebase_core.dart, package:flutter/foundation.dart, package:in_app_review/in_app_review.dart, package:shared_preferences/shared_preferences.dart, DefaultFirebaseOptions, UnsupportedError, TextScaleProvider, _ensureFirstLaunchStamped (+1 more)

### Community 28 - "Community 28"
Cohesion: 0.18
Nodes (10): app_theme.dart, package:url_launcher/url_launcher.dart, Icon, launchUrl, _requestNotificationPermission, _show, showDialog, SizedBox (+2 more)

### Community 29 - "Community 29"
Cohesion: 0.18
Nodes (10): build, Icon, launchUrl, _open, SafeArea, showModalBottomSheet, showSupportSheet, SizedBox (+2 more)

### Community 30 - "Community 30"
Cohesion: 0.22
Nodes (8): package:flutter/material.dart, AppUser, _roleFromString, _roleToString, Note, _syncAppColors, ThemeProvider, ../utils/app_theme.dart

### Community 31 - "Community 31"
Cohesion: 0.18
Nodes (10): ../providers/auth_provider.dart, ../providers/note_provider.dart, AcknowledgeSheet, _AcknowledgeSheetState, build, Container, showModalBottomSheet, SizedBox (+2 more)

### Community 32 - "Community 32"
Cohesion: 0.18
Nodes (10): build, Center, DateFormat, _dateKey, FilteredNotesScreen, _groupedList, ListView, Scaffold (+2 more)

### Community 33 - "Community 33"
Cohesion: 0.2
Nodes (9): ../services/patient_service.dart, cancelSubscription, clearSelectedPatient, dispose, PatientProvider, pauseStream, selectPatient, subscribeForWards (+1 more)

### Community 34 - "Community 34"
Cohesion: 0.2
Nodes (9): firebase_options.dart, providers/providers.dart, build, main, MaterialApp, MediaQuery, MultiProvider, WardlyApp (+1 more)

### Community 35 - "Community 35"
Cohesion: 0.2
Nodes (9): package:intl/intl.dart, formatDate, formatDateShort, formatTime, getAvatarColor, getInitials, isToday, isUrgent (+1 more)

### Community 36 - "Community 36"
Cohesion: 0.2
Nodes (6): package:cloud_firestore/cloud_firestore.dart, NoteComment, Patient, Ward, _capitalise, MetricsService

### Community 37 - "Community 37"
Cohesion: 0.2
Nodes (8): package:firebase_auth/firebase_auth.dart, package:firebase_messaging/firebase_messaging.dart, package:share_plus/share_plus.dart, PushService, _baseMessage, message, _platformLink, ShareHelper

### Community 38 - "Community 38"
Cohesion: 0.22
Nodes (8): build, Container, _FaqItem, _FaqTile, HelpScreen, Icon, Scaffold, SizedBox

### Community 39 - "Community 39"
Cohesion: 0.22
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 40 - "Community 40"
Cohesion: 0.22
Nodes (8): 1. Firebase Project, 2. Connect Firebase, 3. Deploy Rules, 4. Run, Roles, Setup, Ward ID, Wardly 🏥

### Community 41 - "Community 41"
Cohesion: 0.25
Nodes (7): build, Container, InkWell, PatientCard, SizedBox, Spacer, _statusChip

### Community 42 - "Community 42"
Cohesion: 0.25
Nodes (7): dart:io, package:google_sign_in/google_sign_in.dart, package:http/http.dart, package:sign_in_with_apple/sign_in_with_apple.dart, AuthService, GoogleSignIn, UnsupportedError

### Community 43 - "Community 43"
Cohesion: 0.29
Nodes (6): dart:async, ../services/ward_service.dart, dispose, loadWardStaff, subscribeToWards, WardProvider

### Community 44 - "Community 44"
Cohesion: 0.33
Nodes (5): package:google_fonts/google_fonts.dart, AppColors, AppTheme, BorderSide, ThemeData

### Community 45 - "Community 45"
Cohesion: 0.33
Nodes (5): package:provider/provider.dart, ../providers/theme_provider.dart, build, IconButton, ThemeToggleButton

### Community 46 - "Community 46"
Cohesion: 0.33
Nodes (5): metrics_service.dart, ../models/patient.dart, _deleteNotesFor, flushIfNeeded, PatientService

### Community 47 - "Community 47"
Cohesion: 0.33
Nodes (3): RegisterGeneratedPlugins(), NSWindow, MainFlutterWindow

### Community 48 - "Community 48"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 49 - "Community 49"
Cohesion: 0.4
Nodes (3): db, { getFirestore, FieldValue }, { initializeApp, applicationDefault }

### Community 50 - "Community 50"
Cohesion: 0.4
Nodes (4): build, Row, SizedBox, WardlyBrand

### Community 51 - "Community 51"
Cohesion: 0.4
Nodes (4): build, Center, EmptyState, SizedBox

### Community 52 - "Community 52"
Cohesion: 0.4
Nodes (4): support_sheet.dart, build, IconButton, SupportAppBarAction

### Community 54 - "Community 54"
Cohesion: 0.5
Nodes (3): ../models/ward.dart, WardService, ../utils/app_constants.dart

## Knowledge Gaps
- **686 isolated node(s):** `Generates Play Store visual assets for Wardly.  Layout philosophy (after design`, `Locate a colour-emoji font. Pillow 9+ can render colour glyphs     when you pass`, `Loads the colour-emoji font. Pillow's color-emoji path requires     a specific s`, `Draws a single colour-emoji glyph centred at (cx, cy), scaled to     `target_siz`, `Mix rgb with white at the given alpha (0-255).` (+681 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 30` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 15`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 25`, `Community 28`, `Community 29`, `Community 31`, `Community 32`, `Community 34`, `Community 35`, `Community 38`, `Community 41`, `Community 44`, `Community 45`, `Community 50`, `Community 51`, `Community 52`?**
  _High betweenness centrality (0.163) - this node is a cross-community bridge._
- **Why does `../utils/app_theme.dart` connect `Community 30` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 15`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 25`, `Community 29`, `Community 31`, `Community 32`, `Community 34`, `Community 38`, `Community 41`, `Community 50`, `Community 51`?**
  _High betweenness centrality (0.109) - this node is a cross-community bridge._
- **Why does `package:google_fonts/google_fonts.dart` connect `Community 44` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 15`, `Community 17`, `Community 18`, `Community 20`, `Community 21`, `Community 22`, `Community 23`, `Community 24`, `Community 25`, `Community 28`, `Community 29`, `Community 31`, `Community 32`, `Community 38`, `Community 41`, `Community 50`, `Community 51`?**
  _High betweenness centrality (0.103) - this node is a cross-community bridge._
- **What connects `Generates Play Store visual assets for Wardly.  Layout philosophy (after design`, `Locate a colour-emoji font. Pillow 9+ can render colour glyphs     when you pass`, `Loads the colour-emoji font. Pillow's color-emoji path requires     a specific s` to the rest of the system?**
  _686 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._