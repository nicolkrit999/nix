{ delib, ... }:
delib.module {
  name = "krit.programs.discord";

  home.ifEnabled.programs.nixcord = {
    config.plugins = {
      accountPanelServerProfile.enable = true;
      addAttachments.enable = true;
      alwaysAnimate.enable = true;
      alwaysExpandRoles.enable = true;
      alwaysTrust.enable = true;
      autoDndWhilePlaying = {
        enable = true;
        statusToSet = "dnd";
      };
      betterFolders.enable = true;
      betterGifAltText.enable = true;
      betterGifPicker.enable = true;
      betterInvites.enable = true;
      betterRoleContext.enable = true;
      betterSessions.enable = true;
      betterSettings.enable = true;
      betterUploadButton.enable = true;
      biggerStreamPreview.enable = true;
      cancelFriendRequest.enable = true;
      characterCounter = {
        enable = true;
        colorEffects = true;
      };
      clearUrls.enable = true;
      clickableRoles.enable = true;
      clientTheme.enable = true;
      clipsEnhancements = {
        enable = true;
        richPresenceTagging = "whenMatched";
      };
      copyEmojiMarkdown = {
        enable = true;
        copyUnicode = true;
      };
      copyFileContents.enable = true;
      copyUserUrls.enable = true;
      crashHandler.enable = true;
      cursorBuddy.enable = true;
      decor = {
        enable = true;
        agreedToGuidelines = true;
      };
      directFileDownload.enable = true;
      disableCallIdle.enable = true;
      downloadAllAttachments = {
        enable = true;
        downloadAllFileTypes = true;
      };
      dragify.enable = true;
      equicordToolbox.enable = true;
      exportMessages = {
        enable = true;
        openFileAfterExport = true;
        exportContacts = false;
      };
      fakeNitro.enable = true;
      favoriteAnything = {
        enable = true;
        localThumbnails = false;
      };
      favoriteEmojiFirst.enable = true;
      fixImagesQuality.enable = true;
      fixSpotifyEmbeds.enable = true;
      fixYoutubeEmbeds = {
        enable = true;
        youtubeDescription = true;
      };
      friendCodes.enable = true;
      friendInvites.enable = true;
      fullSearchContext.enable = true;
      gifProviderSwitcher = {
        enable = true;
        provider = [ "tenor" ];
      };
      imageZoom.enable = true;
      limitlessScreenshare = {
        enable = true;
        maxFps = 240;
        maxResolution = 2160;
        roundResolution = false;
        resolutions = [
          {
            label = "480p";
            value = 480;
          }
          {
            label = "720p";
            value = 720;
          }
          {
            label = "1080p";
            value = 1080;
          }
          {
            label = "1440p";
            value = 1440;
          }
          {
            label = "2160p";
            value = 2160;
          }
          {
            label = "Source";
            value = 0;
          }
        ];
        fpss = [
          {
            label = "15fps";
            value = 15;
          }
          {
            label = "30fps";
            value = 30;
          }
          {
            label = "60fps";
            value = 60;
          }
          {
            label = "120fps";
            value = 120;
          }
          {
            label = "240fps";
            value = 240;
          }
        ];
      };
      memberCount = {
        enable = true;
        toolTip = true;
        memberList = false;
        voiceActivity = true;
      };
      messageLogger = {
        enable = true;
        ignoreBots = false;
      };
      musicControls = {
        enable = true;
        showSpotifyControls = true;
      };
      neverPausePreviews.enable = true;
      newGuildSettings.enable = true;
      noNitroUpsell.enable = true;
      noOnboardingDelay.enable = true;
      noTrack.enable = true;
      openInApp = {
        enable = true;
        epic = false;
        itunes = false;
        spotify = true;
        steam = true;
        telegram = true;
        tidal = false;
        vrcx = false;
      };
      permissionsViewer.enable = true;
      pictureInPicture.enable = true;
      # userBasedCategoryList (personal IDs) is kept out of the public repo
      pinDms.enable = true;
      plainFolderIcon.enable = true;
      previewMessage.enable = true;
      readAllNotificationsButton.enable = true;
      reverseImageSearch.enable = true;
      reviewDb.enable = true;
      sendTimestamps.enable = true;
      serverInfo = {
        enable = true;
        sorting = "displayname";
      };
      settings.enable = true;
      silentTyping.enable = true;
      spotifyCrack.enable = true;
      spotifyShareCommands.enable = true;
      supportHelper.enable = true;
      translate.enable = true;
      unindent.enable = true;
      validUser.enable = true;
      voiceDownload.enable = true;
      voiceMessages.enable = true;
      youtubeAdblock.enable = true;
    };
  };
}
