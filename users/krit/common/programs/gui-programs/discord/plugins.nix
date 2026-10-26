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
      betterRoleContext.enable = true;
      betterSessions.enable = true;
      betterSettings.enable = true;
      betterUploadButton.enable = true;
      biggerStreamPreview.enable = true;
      characterCounter = {
        enable = true;
        colorEffects = true;
      };
      clearUrls.enable = true;
      clientTheme.enable = true;
      copyEmojiMarkdown = {
        enable = true;
        copyUnicode = true;
      };
      copyFileContents.enable = true;
      copyUserUrls.enable = true;
      crashHandler.enable = true;
      directFileDownload.enable = true;
      disableCallIdle.enable = true;
      fakeNitro.enable = true;
      favoriteEmojiFirst.enable = true;
      fixImagesQuality.enable = true;
      fixSpotifyEmbeds.enable = true;
      friendInvites.enable = true;
      fullSearchContext.enable = true;
      imageZoom.enable = true;
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
      newGuildSettings.enable = true;
      noOnboardingDelay.enable = true;
      noTrack.enable = true;
      oneko.enable = true;
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
      settings.enable = true;
      silentTyping.enable = true;
      spotifyControls.enable = true;
      spotifyCrack.enable = true;
      spotifyShareCommands.enable = true;
      supportHelper.enable = true;
      translate.enable = true;
      unindent.enable = true;
      validUser.enable = true;
      vencordToolbox.enable = true;
      voiceDownload.enable = true;
      voiceMessages.enable = true;
      youtubeAdblock.enable = true;
    };

    extraConfig.plugins.BetterNotesBox = {
      enable = true;
      hide = false;
    };
  };
}
