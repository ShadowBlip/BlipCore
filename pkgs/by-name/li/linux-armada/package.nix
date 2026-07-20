# Kernel Armada
# Based on the configuration and patch series from the Armada project.
# Source: https://github.com/virtudude/armada-packages/blob/16342cb3ae5b8ad34a74cbfd4914c43dfae11995/kernel/scripts/build-kernel.sh
{
  lib,
  fetchurl,
  buildLinux,
  ...
}:
let
  kernel-version = "7.0.11";
  ogc-revision = "armada1";
  version = "${kernel-version}-${ogc-revision}";
  kernelSrc = fetchurl {
    url = "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${kernel-version}.tar.xz";
    hash = "sha256-5WyDVt2gETamBBxu+DK9Dsmb0tNd/5eDKqXsEO0BQwQ=";
  };
  configs = [
    (fetchurl {
      url = "https://github.com/virtudude/armada-packages/blob/16342cb3ae5b8ad34a74cbfd4914c43dfae11995/kernel/config/armada-kernel.config.overrides";
      hash = "sha256-kjT54hCq6xF9IUXuH8khq7+HvPBtW3jWMyJsOYAJraA=";
    })
  ];

  # Build the structured kernel config from one or more configs from the `configs` array
  kernelConfig = lib.pipe configs [
    # Read each config file into a string
    (configs: map (config: builtins.readFile config) configs)
    # Join all configs into a single string
    (configs: lib.strings.join "\n" configs)
    # Split the single config into lines
    (config: lib.strings.splitString "\n" config)
    # Find all lines that start with "CONFIG_"
    (lines: lib.strings.filter (line: (builtins.match "^CONFIG_.*" line) != null) lines)
    # Strip the "CONFIG_" prefix of each kernel option so it can be in `structuredExtraConfig` format
    # E.g. "CONFIG_NTSYNC=m" -> "NTSYNC=m"
    (lines: map (line: lib.strings.removePrefix "CONFIG_" line) lines)
    # Convert each stripped line into key/value pairs
    # E.g. "NTSYNC=m" -> ["NTSYNC" "m"]
    (lines_stripped: map (line: builtins.split "=" line) lines_stripped)
    # Convert each key/value pair into an attribute set in the form of: {"name" = key; "value" = value;}
    # E.g. ["NTSYNC" "m"] -> {"name" = "NTSYNC"; "value" = lib.kernel.module;}
    (kvPairs: map kvpairToOption kvPairs)
    # Convert the list of attribute sets into a single combined attribute set that will
    # be used as the `structuredExtraConfig`.
    # E.g.
    # {
    #   NTSYNC = lib.kernel.module;
    #   HID_ASUS = lib.kernel.module;
    #   ...
    # }
    (attrSets: builtins.listToAttrs attrSets)
  ];

  # Function for converting a key/value pair into a kernel option attribute set
  # E.g. "NTSYNC=m" -> {"name": "NTSYNC", "value": lib.kernel.module}
  kvpairToOption =
    kv_pair:
    if (builtins.length kv_pair) == 1 then
      let
        key = builtins.elemAt kv_pair 0;
      in
      {
        "name" = key;
        "value" = lib.mkDefault lib.kernel.unset;
      }
    else
      let
        key = builtins.elemAt kv_pair 0;
        value = builtins.elemAt kv_pair 1;
      in
      {
        "name" = key;
        "value" =
          if value == "y" then
            lib.mkDefault lib.kernel.yes
          else if value == "m" then
            lib.mkDefault lib.kernel.module
          else if value == "n" then
            lib.mkDefault lib.kernel.no
          else
            lib.mkDefault lib.kernel.unset;
      };
in

buildLinux {
  version = version;
  modDirVersion = version;
  src = kernelSrc;

  structuredExtraConfig = {
    LOCALVERSION = lib.kernel.freeform "-${ogc-revision}";
  }
  // kernelConfig;

  buildDTBs = true;

  kernelPatches = [
    # ============== Display / DRM ==============
    {
      name = "0002-qcom-dispcc-sm8550-Fix-disp_cc_mdss_mdp_clk_src.patch";
      patch = ./patches/0002-qcom-dispcc-sm8550-Fix-disp_cc_mdss_mdp_clk_src.patch;
    }
    {
      name = "0004-drm-msm-a6xx-Enable-IFPC-on-Adreno-740.patch";
      patch = ./patches/0004-drm-msm-a6xx-Enable-IFPC-on-Adreno-740.patch;
    }
    {
      name = "0010-msm-resource-cleanup.patch";
      patch = ./patches/0010-msm-resource-cleanup.patch;
    }
    {
      name = "0048-drm-msm-dsi-reparent-byte-pixel-src-to-xo-on-disable.patch";
      patch = ./patches/0048-drm-msm-dsi-reparent-byte-pixel-src-to-xo-on-disable.patch;
    }
    {
      name = "0051-gpu-panel-add-Pocket-ACE-panel-driver.patch";
      patch = ./patches/0051-gpu-panel-add-Pocket-ACE-panel-driver.patch;
    }
    {
      name = "0052-gpu-panel-add-Pocket-DMG-panel-driver.patch";
      patch = ./patches/0052-gpu-panel-add-Pocket-DMG-panel-driver.patch;
    }
    {
      name = "0053-gpu-panel-add-Pocket-DS-lower-panel-driver.patch";
      patch = ./patches/0053-gpu-panel-add-Pocket-DS-lower-panel-driver.patch;
    }
    {
      name = "0055_Synaptics-TD4328-LCD-panel.patch";
      patch = ./patches/0055_Synaptics-TD4328-LCD-panel.patch;
    }
    {
      name = "0056_Xm-Plus-XM91080G-panel.patch";
      patch = ./patches/0056_Xm-Plus-XM91080G-panel.patch;
    }
    {
      name = "0057_Chipone-ICNA35XX-panel.patch";
      patch = ./patches/0057_Chipone-ICNA35XX-panel.patch;
    }
    {
      name = "0057_DDIC-CH13726A-panel.patch";
      patch = ./patches/0057_DDIC-CH13726A-panel.patch;
    }
    {
      name = "0062-gpu-drm-panel-add-wt0630-panel.patch";
      patch = ./patches/0062-gpu-drm-panel-add-wt0630-panel.patch;
    }
    {
      name = "0104-drm-panel-Add-Retroid-Pocket-6-panel.patch";
      patch = ./patches/0104-drm-panel-Add-Retroid-Pocket-6-panel.patch;
    }

    # ============== Panel power + backlight ==============
    {
      name = "0058_AYN-Odin2-Mini--backlight.patch";
      patch = ./patches/0058_AYN-Odin2-Mini--backlight.patch;
    }
    {
      name = "0060-backlight-Add-SY7758-LED-driver.patch";
      patch = ./patches/0060-backlight-Add-SY7758-LED-driver.patch;
    }
    {
      name = "0060-dt-bindings-silergy-sy7758.patch";
      patch = ./patches/0060-dt-bindings-silergy-sy7758.patch;
    }
    {
      name = "0061-regulator-add-sgm3804-i2c-regulator-for-panel-power-.patch";
      patch = ./patches/0061-regulator-add-sgm3804-i2c-regulator-for-panel-power-.patch;
    }

    # ============== Touchscreen ==============
    {
      name = "0015-touchscreen-edt-ft5x06-allow-to-override-input-name.patch";
      patch = ./patches/0015-touchscreen-edt-ft5x06-allow-to-override-input-name.patch;
    }
    {
      name = "0030-input-rmi4-add-reset-gpio.patch";
      patch = ./patches/0030-input-rmi4-add-reset-gpio.patch;
    }
    {
      name = "0032-rmi4-silence-spam-irq-errors.patch";
      patch = ./patches/0032-rmi4-silence-spam-irq-errors.patch;
    }
    {
      name = "0053-add-hynitron-touchscreen.patch";
      patch = ./patches/0053-add-hynitron-touchscreen.patch;
    }
    {
      name = "0053-edt-ft5x06-add-no_regmap_bulk_read-option.patch";
      patch = ./patches/0053-edt-ft5x06-add-no_regmap_bulk_read-option.patch;
    }
    {
      name = "0059_AYN-Odin2-Mini--hynitron--cstxxx.patch";
      patch = ./patches/0059_AYN-Odin2-Mini--hynitron--cstxxx.patch;
    }
    {
      # keep before the driver
      name = "0060-input-touchscreen-add-synaptics-dsx-kconfig.patch";
      patch = ./patches/0060-input-touchscreen-add-synaptics-dsx-kconfig.patch;
    }
    {
      name = "0060-input-touchscreen-add-synaptics-dsx-driver.patch";
      patch = ./patches/0060-input-touchscreen-add-synaptics-dsx-driver.patch;
    }

    # ============== Input / Gamepad ==============
    {
      name = "0031_input--Add-driver-for-RSInput-Gamepad.patch";
      patch = ./patches/0031_input--Add-driver-for-RSInput-Gamepad.patch;
    }
    {
      name = "0508-input-rsinput-add-pm-resume-to-reinit-mcu-after-suspend.patch";
      patch = ./patches/0508-input-rsinput-add-pm-resume-to-reinit-mcu-after-suspend.patch;
    }
    {
      name = "0504-Enable-64-bit-processes-to-use-compat-input-syscalls.patch";
      patch = ./patches/0504-Enable-64-bit-processes-to-use-compat-input-syscalls.patch;
    }
    {
      name = "0506-usbcore-add-interrupt-interval-override.patch";
      patch = ./patches/0506-usbcore-add-interrupt-interval-override.patch;
    }

    # ============== USB boot hang fix ==============
    {
      name = "0071-HACK-fix-usb-boot-hang.patch";
      patch = ./patches/0071-HACK-fix-usb-boot-hang.patch;
    }

    # ============== Haptics ==============
    #{
    #  name = "1000-add-qcom-haptics-driver.patch";
    #  patch = ./patches/1000-add-qcom-haptics-driver.patch;
    #}
    #{
    #  name = "1002-haptics-driver-support-periodic-sine-and-fixes.patch";
    #  patch = ./patches/1002-haptics-driver-support-periodic-sine-and-fixes.patch;
    #}
    #{
    #  # rumble — keep after 1000/1002 (patches qcom-hv-haptics.c) and before 1300
    #  name = "1003-rsinput-add-ff.patch";
    #  patch = ./patches/1003-rsinput-add-ff.patch;
    #}
    #{
    #  name = "1300-input-rsinput-ranges.patch";
    #  patch = ./patches/1300-input-rsinput-ranges.patch;
    #}

    # ============== Audio ==============
    {
      name = "0036_ASoC--qcom--sc8280xp-Add-support-for-Primary-I2S.patch";
      patch = ./patches/0036_ASoC--qcom--sc8280xp-Add-support-for-Primary-I2S.patch;
    }
    {
      name = "0047_ASoC--codecs--aw88166--AYN-Odin2-Specific-modifica.patch";
      patch = ./patches/0047_ASoC--codecs--aw88166--AYN-Odin2-Specific-modifica.patch;
    }

    # ============== LED / RGB ==============
    {
      name = "0033_leds--Add-driver-for-HEROIC-HTR3212.patch";
      patch = ./patches/0033_leds--Add-driver-for-HEROIC-HTR3212.patch;
    }

    # ============== PWM ==============
    {
      name = "0050_pmk8550-pwm.patch";
      patch = ./patches/0050_pmk8550-pwm.patch;
    }
    {
      name = "0054_sn3112-pwm-driver.patch";
      patch = ./patches/0054_sn3112-pwm-driver.patch;
    }

    # ============== Storage ==============
    {
      name = "0042_mmc--sdhci-msm--Toggle-the-FIFO-write-clock-after-.patch";
      patch = ./patches/0042_mmc--sdhci-msm--Toggle-the-FIFO-write-clock-after-.patch;
    }

    # ============== SoC / Platform ==============
    {
      name = "20260424_neil_armstrong_arm64_dts_qcom_sm8_456_50_add_missing_cx_power_domain_to_gcc.patch";
      patch = ./patches/20260424_neil_armstrong_arm64_dts_qcom_sm8_456_50_add_missing_cx_power_domain_to_gcc.patch;
    }
    {
      name = "v6_20260210_quic_utiwari_crypto_qce_add_runtime_pm_and_interconnect_bandwidth_scaling_support.patch";
      patch = ./patches/v6_20260210_quic_utiwari_crypto_qce_add_runtime_pm_and_interconnect_bandwidth_scaling_support.patch;
    }
    {
      name = "0504-wakeup-qcom-ipcc-remove-IRQF-NO-SUSPEND.patch";
      patch = ./patches/0504-wakeup-qcom-ipcc-remove-IRQF-NO-SUSPEND.patch;
    }
    {
      name = "0505-msm_gem-lock-before-put_iova_spaces.patch";
      patch = ./patches/0505-msm_gem-lock-before-put_iova_spaces.patch;
    }

    # ============== SM8550 DTSI prereqs (AYN common DTSI references these) ==============
    {
      name = "0100-SM8550-Fix-L2-cache-for-CPU2-and-add-cache-sizes.patch";
      patch = ./patches/0100-SM8550-Fix-L2-cache-for-CPU2-and-add-cache-sizes.patch;
    }
    {
      name = "0101-v3_20260219_webgeek1234_arm64_qcom_sm8550_add_ddr_llcc_l3_cpu_bandwidth_scaling.patch";
      patch = ./patches/0101-v3_20260219_webgeek1234_arm64_qcom_sm8550_add_ddr_llcc_l3_cpu_bandwidth_scaling.patch;
    }
    {
      name = "0102-20240424_wuxilin123_ayn_odin_2_support.patch";
      patch = ./patches/0102-20240424_wuxilin123_ayn_odin_2_support.patch;
    }
    {
      name = "0103_arm64--dts--qcom--sm8550--add-UART15.patch";
      patch = ./patches/0103_arm64--dts--qcom--sm8550--add-UART15.patch;
    }
    {
      name = "0120-20250728_konradybcio_gpu_cc_power_requirements_reality_check.patch";
      patch = ./patches/0120-20250728_konradybcio_gpu_cc_power_requirements_reality_check.patch;
    }
    {
      name = "0122-interconnect__qcom__sm8550__Enable_QoS_configuration.patch";
      patch = ./patches/0122-interconnect__qcom__sm8550__Enable_QoS_configuration.patch;
    }
    {
      name = "0154-dts-qcom-sm8550-add-opp-acd-level.patch";
      patch = ./patches/0154-dts-qcom-sm8550-add-opp-acd-level.patch;
    }
    {
      name = "0200-ASoC-wcd938x-add-DMIC-DAPM-inputs.patch";
      patch = ./patches/0200-ASoC-wcd938x-add-DMIC-DAPM-inputs.patch;
    }

    # ============== System tweaks ==============
    {
      name = "0500-ROCKNIX-set-boot-fanspeed.patch";
      patch = ./patches/0500-ROCKNIX-set-boot-fanspeed.patch;
    }
    {
      name = "0501-ROCKNIX-fix-wifi-and-bt-mac.patch";
      patch = ./patches/0501-ROCKNIX-fix-wifi-and-bt-mac.patch;
    }
    {
      name = "0503-ROCKNIX-battery-name.patch";
      patch = ./patches/0503-ROCKNIX-battery-name.patch;
    }

    # ============== SM8650 (AYANEO Pocket S2, KONKR Pocket FIT) ==============
    {
      name = "0006-add-hw_params-callback-function-to-drm_connector_hdmi_audio_ops.patch";
      patch = ./patches/0006-add-hw_params-callback-function-to-drm_connector_hdmi_audio_ops.patch;
    }
    {
      name = "0007-audioreach-Add-dedicated-WSA2-support.patch";
      patch = ./patches/0007-audioreach-Add-dedicated-WSA2-support.patch;
    }
    {
      name = "0040-dts-qcom-sm8650-Add-sound-DAI-prefix-for-DP.patch";
      patch = ./patches/0040-dts-qcom-sm8650-Add-sound-DAI-prefix-for-DP.patch;
    }
    {
      name = "0050-update-sm8650-dtsi.patch";
      patch = ./patches/0050-update-sm8650-dtsi.patch;
    }
    {
      name = "v2_20260420_neil_armstrong_arm64_qcom_sm8650_misc_enhancements.patch";
      patch = ./patches/v2_20260420_neil_armstrong_arm64_qcom_sm8650_misc_enhancements.patch;
    }
    {
      name = "0063-gpu-drm-panel-add-pocket-fit-panel.patch";
      patch = ./patches/0063-gpu-drm-panel-add-pocket-fit-panel.patch;
    }
    {
      name = "0064-add-chipone-tddi-touchscreen.patch";
      patch = ./patches/0064-add-chipone-tddi-touchscreen.patch;
    }

    # ============== SM8750 (AYN Odin 3) ==============
    {
      name = "0026-dt-bindings-arm-qcom-ids-Add-SoC-ID-for-CQ8725S.patch";
      patch = ./patches/0026-dt-bindings-arm-qcom-ids-Add-SoC-ID-for-CQ8725S.patch;
    }
    {
      name = "0027-soc-qcom-socinfo-Add-CQ8725S-SoC-ID.patch";
      patch = ./patches/0027-soc-qcom-socinfo-Add-CQ8725S-SoC-ID.patch;
    }
    {
      name = "0034-arm64-dts-qcom-sm8750-Add-UART15.patch";
      patch = ./patches/0034-arm64-dts-qcom-sm8750-Add-UART15.patch;
    }
    {
      name = "sm8750-gpucc-clock-controller.patch";
      patch = ./patches/sm8750-gpucc-clock-controller.patch;
    }
    {
      name = "sm8750-add-display-gpu-nodes.patch";
      patch = ./patches/sm8750-add-display-gpu-nodes.patch;
    }
    {
      name = "sm8750-adreno-a830-gpu-driver.patch";
      patch = ./patches/sm8750-adreno-a830-gpu-driver.patch;
    }
    {
      name = "0039-wifi-ath12k-add-initial-hardware-definition-for-WCN7.patch";
      patch = ./patches/0039-wifi-ath12k-add-initial-hardware-definition-for-WCN7.patch;
    }
    {
      name = "0040-wifi-ath12k-send-QDSS-config-when-CNSS_QDSS_CFG_MISS.patch";
      patch = ./patches/0040-wifi-ath12k-send-QDSS-config-when-CNSS_QDSS_CFG_MISS.patch;
    }
    {
      name = "0041-wifi-ath12k-disable-CNSS_QDSS_CFG_MISS_V01-for-the-W.patch";
      patch = ./patches/0041-wifi-ath12k-disable-CNSS_QDSS_CFG_MISS_V01-for-the-W.patch;
    }
    {
      name = "0042-PCI-pwrctrl-pwrseq-add-support-for-WCN7860.patch";
      patch = ./patches/0042-PCI-pwrctrl-pwrseq-add-support-for-WCN7860.patch;
    }
    {
      name = "0043-power-sequencing-qcom-wcn-add-support-for-WCN7860.patch";
      patch = ./patches/0043-power-sequencing-qcom-wcn-add-support-for-WCN7860.patch;
    }
    {
      name = "0044-clk-qcom-gcc-sm8750-Do-not-turn-off-PCIe-GDSCs-durin.patch";
      patch = ./patches/0044-clk-qcom-gcc-sm8750-Do-not-turn-off-PCIe-GDSCs-durin.patch;
    }
    {
      name = "0045-Bluetooth-qca-add-WCN7860-support.patch";
      patch = ./patches/0045-Bluetooth-qca-add-WCN7860-support.patch;
    }
    {
      name = "0600-ROCKNIX-sm8750-tsens-thermal-zones.patch";
      patch = ./patches/0600-ROCKNIX-sm8750-tsens-thermal-zones.patch;
    }

    # ============== DTS ==============
    {
      name = "cq8725s-ayn-common.dtsi.patch";
      patch = ./dts/cq8725s-ayn-common.dtsi.patch;
    }
    {
      name = "cq8725s-ayn-odin3.dts.patch";
      patch = ./dts/cq8725s-ayn-odin3.dts.patch;
    }
    {
      name = "cq8725s-ayn-odin3.dts-makefile.patch";
      patch = ./dts/cq8725s-ayn-odin3.dts-makefile.patch;
    }

  ];
}
