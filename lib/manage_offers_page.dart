import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_translations.dart';

class ManageOffersPage extends StatefulWidget {
  final String salonId;

  const ManageOffersPage({
    super.key,
    required this.salonId,
  });

  @override
  State<ManageOffersPage> createState() => _ManageOffersPageState();
}

class _ManageOffersPageState extends State<ManageOffersPage> {
  final DatabaseReference rootRef = FirebaseDatabase.instance.ref();

  final titleArController = TextEditingController();
  final titleEnController = TextEditingController();
  final priceController = TextEditingController();

  late DatabaseReference offersRef;
  late DatabaseReference servicesRef;

  String currentLang = 'ar';
  String? editingOfferId;

  bool active = true;
  bool saving = false;

  int startHour = 13;
  int startMinute = 0;
  int endHour = 17;
  int endMinute = 0;

  final Set<int> selectedDays = {7};
  final Set<String> selectedServices = {};

  bool get isArabic => currentLang == 'ar';

  String t(String key) => tr(key, currentLang);

  Color get background => const Color(0xFF07111F);
  Color get cardColor => const Color(0xFF101B2D);
  Color get fieldColor => const Color(0xFF13233A);
  Color get borderColor => const Color(0xFF304763);
  Color get greenColor => const Color(0xFF22C55E);
  Color get orangeColor => const Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    offersRef = rootRef
        .child('salons')
        .child(widget.salonId)
        .child('offers');

    servicesRef = rootRef
        .child('salons')
        .child(widget.salonId)
        .child('services');
  }

  @override
  void dispose() {
    titleArController.dispose();
    titleEnController.dispose();
    priceController.dispose();
    super.dispose();
  }

  int toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String dayName(int day) {
    const ar = {
      1: 'الاثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };

    const en = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    return isArabic ? ar[day]! : en[day]!;
  }

  String formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  Future<void> saveOffer() async {
    final titleAr = titleArController.text.trim();
    final titleEn = titleEnController.text.trim();
    final price = toInt(priceController.text);

    if (titleAr.isEmpty) {
      showMessage(isArabic ? 'اكتب اسم العرض بالعربي' : 'Enter the Arabic offer name');
      return;
    }

    if (price <= 0) {
      showMessage(isArabic ? 'اكتب سعرًا صحيحًا للعرض' : 'Enter a valid offer price');
      return;
    }

    if (selectedServices.isEmpty) {
      showMessage(isArabic ? 'اختار خدمة واحدة على الأقل' : 'Select at least one service');
      return;
    }

    if (selectedDays.isEmpty) {
      showMessage(isArabic ? 'اختار يومًا واحدًا على الأقل' : 'Select at least one day');
      return;
    }

    final start = startHour * 60 + startMinute;
    final end = endHour * 60 + endMinute;

    if (end <= start) {
      showMessage(
        isArabic
            ? 'وقت نهاية العرض لازم يكون بعد وقت بدايته في نفس اليوم'
            : 'The end time must be after the start time on the same day',
      );
      return;
    }

    setState(() => saving = true);

    try {
      final servicesSnapshot = await servicesRef.get();
      final rawServices = servicesSnapshot.value;

      final Map<dynamic, dynamic> servicesMap =
          rawServices is Map
              ? Map<dynamic, dynamic>.from(rawServices)
              : <dynamic, dynamic>{};

      final serviceDetails = <Map<String, dynamic>>[];

      for (final id in selectedServices) {
        final value = servicesMap[id];

        if (value is Map) {
          final service = Map<dynamic, dynamic>.from(value);

          serviceDetails.add({
            'id': id,
            'nameAr': (service['nameAr'] ?? service['name'] ?? '').toString(),
            'nameEn': (service['nameEn'] ?? service['nameAr'] ?? service['name'] ?? '').toString(),
            'originalPrice': toInt(service['price']),
            'duration': toInt(service['duration']),
          });
        }
      }

      if (serviceDetails.length != selectedServices.length) {
        showMessage(
          isArabic
              ? 'بعض الخدمات المختارة لم تعد موجودة. اختار الخدمات من جديد.'
              : 'Some selected services no longer exist. Select them again.',
        );
        return;
      }

      final data = <String, dynamic>{
        'titleAr': titleAr,
        'titleEn': titleEn,
        'price': price,
        'active': active,
        'days': selectedDays.toList()..sort(),
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'serviceIds': selectedServices.toList(),
        'services': serviceDetails,
        'updatedAt': ServerValue.timestamp,
      };

      if (editingOfferId == null) {
        final newRef = offersRef.push();
        await newRef.set({
          ...data,
          'id': newRef.key,
          'createdAt': ServerValue.timestamp,
        });
      } else {
        await offersRef.child(editingOfferId!).update(data);
      }

      if (!mounted) return;

      clearForm();

      showMessage(
        isArabic ? 'تم حفظ العرض بنجاح' : 'Offer saved successfully',
      );
    } catch (e) {
      showMessage('${t('error')}: $e');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void clearForm() {
    titleArController.clear();
    titleEnController.clear();
    priceController.clear();

    setState(() {
      editingOfferId = null;
      active = true;
      startHour = 13;
      startMinute = 0;
      endHour = 17;
      endMinute = 0;
      selectedDays
        ..clear()
        ..add(7);
      selectedServices.clear();
    });
  }

  void editOffer(String id, Map<String, dynamic> offer) {
    titleArController.text = (offer['titleAr'] ?? '').toString();
    titleEnController.text = (offer['titleEn'] ?? '').toString();
    priceController.text = toInt(offer['price']).toString();

    final days = offer['days'];
    final services = offer['serviceIds'];

    setState(() {
      editingOfferId = id;
      active = offer['active'] == true;

      startHour = toInt(offer['startHour']).clamp(0, 23);
      startMinute = toInt(offer['startMinute']).clamp(0, 59);
      endHour = toInt(offer['endHour']).clamp(0, 23);
      endMinute = toInt(offer['endMinute']).clamp(0, 59);

      selectedDays
        ..clear()
        ..addAll(
          days is List
              ? days.map((e) => toInt(e)).where((d) => d >= 1 && d <= 7)
              : <int>[],
        );

      selectedServices
        ..clear()
        ..addAll(
          services is List
              ? services.map((e) => e.toString())
              : <String>[],
        );
    });
  }

  Future<void> toggleOffer(String id, bool value) async {
    try {
      await offersRef.child(id).update({
        'active': value,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      showMessage('${t('error')}: $e');
    }
  }

  Future<void> deleteOffer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          isArabic ? 'حذف العرض' : 'Delete offer',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          isArabic
              ? 'هل أنت متأكد أنك تريد حذف هذا العرض؟'
              : 'Are you sure you want to delete this offer?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await offersRef.child(id).remove();

      if (editingOfferId == id) {
        clearForm();
      }

      showMessage(isArabic ? 'تم حذف العرض' : 'Offer deleted');
    } catch (e) {
      showMessage('${t('error')}: $e');
    }
  }

  Widget field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: fieldColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget timeDropdown({
    required String label,
    required int hour,
    required int minute,
    required ValueChanged<int> onHourChanged,
    required ValueChanged<int> onMinuteChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: hour,
                dropdownColor: cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Hour',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: List.generate(
                  24,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onHourChanged(v);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: minute,
                dropdownColor: cardColor,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Minute',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('00')),
                  DropdownMenuItem(value: 15, child: Text('15')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 45, child: Text('45')),
                ],
                onChanged: (v) {
                  if (v != null) onMinuteChanged(v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sectionTitle(
            editingOfferId == null
                ? (isArabic ? 'إضافة عرض جديد' : 'Add new offer')
                : (isArabic ? 'تعديل العرض' : 'Edit offer'),
          ),
          field(
            controller: titleArController,
            label: isArabic ? 'اسم العرض بالعربي' : 'Offer name in Arabic',
          ),
          const SizedBox(height: 12),
          field(
            controller: titleEnController,
            label: isArabic ? 'اسم العرض بالإنجليزي' : 'Offer name in English',
          ),
          const SizedBox(height: 12),
          field(
            controller: priceController,
            label: isArabic ? 'سعر العرض بالجنيه' : 'Offer price in EGP',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 18),
          sectionTitle(isArabic ? 'اختيار الخدمات' : 'Choose services'),
          StreamBuilder<DatabaseEvent>(
            stream: servicesRef.onValue,
            builder: (context, snapshot) {
              final raw = snapshot.data?.snapshot.value;

              if (raw is! Map || raw.isEmpty) {
                return Text(
                  isArabic ? 'لا توجد خدمات في الصالون' : 'No salon services found',
                  style: const TextStyle(color: Colors.white70),
                );
              }

              final services = raw.entries.where((e) {
                return e.value is Map;
              }).map((e) {
                return {
                  'id': e.key.toString(),
                  ...Map<String, dynamic>.from(e.value as Map),
                };
              }).toList();

              return Column(
                children: services.map((service) {
                  final id = service['id'].toString();
                  final name = isArabic
                      ? (service['nameAr'] ?? service['name'] ?? '').toString()
                      : (service['nameEn'] ?? service['nameAr'] ?? service['name'] ?? '').toString();

                  return CheckboxListTile(
                    value: selectedServices.contains(id),
                    activeColor: greenColor,
                    checkColor: Colors.white,
                    title: Text(
                      name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${toInt(service['price'])} ${isArabic ? 'جنيه' : 'EGP'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.add(id);
                        } else {
                          selectedServices.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 16),
          sectionTitle(isArabic ? 'أيام العرض' : 'Offer days'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: List.generate(7, (index) {
              final day = index + 1;

              return FilterChip(
                label: Text(dayName(day)),
                selected: selectedDays.contains(day),
                onSelected: (value) {
                  setState(() {
                    if (value) {
                      selectedDays.add(day);
                    } else {
                      selectedDays.remove(day);
                    }
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 18),
          timeDropdown(
            label: isArabic ? 'بداية العرض' : 'Offer start time',
            hour: startHour,
            minute: startMinute,
            onHourChanged: (v) => setState(() => startHour = v),
            onMinuteChanged: (v) => setState(() => startMinute = v),
          ),
          const SizedBox(height: 14),
          timeDropdown(
            label: isArabic ? 'نهاية العرض' : 'Offer end time',
            hour: endHour,
            minute: endMinute,
            onHourChanged: (v) => setState(() => endHour = v),
            onMinuteChanged: (v) => setState(() => endMinute = v),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: active,
            activeTrackColor: greenColor,
            title: Text(
              isArabic ? 'العرض نشط' : 'Offer active',
              style: const TextStyle(color: Colors.white),
            ),
            onChanged: (value) => setState(() => active = value),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: saving ? null : saveOffer,
            icon: const Icon(Icons.save_outlined),
            label: Text(
              saving
                  ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                  : (isArabic ? 'حفظ العرض' : 'Save offer'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: greenColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          TextButton(
            onPressed: clearForm,
            child: Text(isArabic ? 'تفريغ الحقول' : 'Clear form'),
          ),
        ],
      ),
    );
  }

  Widget buildOffersList() {
    return StreamBuilder<DatabaseEvent>(
      stream: offersRef.onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = snapshot.data!.snapshot.value;

        if (raw is! Map || raw.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              isArabic ? 'لا توجد عروض مضافة حتى الآن' : 'No offers added yet',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final offers = raw.entries.where((e) => e.value is Map).map((e) {
          return {
            'id': e.key.toString(),
            ...Map<String, dynamic>.from(e.value as Map),
          };
        }).toList();

        return Column(
          children: offers.map((offer) {
            final id = offer['id'].toString();
            final title = isArabic
                ? (offer['titleAr'] ?? '').toString()
                : (offer['titleEn'] ?? offer['titleAr'] ?? '').toString();

            final days = offer['days'] is List
                ? (offer['days'] as List)
                    .map((e) => toInt(e))
                    .where((d) => d >= 1 && d <= 7)
                    .map(dayName)
                    .join('، ')
                : '';

            final start = formatTime(
              toInt(offer['startHour']),
              toInt(offer['startMinute']),
            );

            final end = formatTime(
              toInt(offer['endHour']),
              toInt(offer['endMinute']),
            );

            return Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isArabic ? 'السعر' : 'Price'}: ${toInt(offer['price'])} ${isArabic ? 'جنيه' : 'EGP'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${isArabic ? 'الأيام' : 'Days'}: $days',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${isArabic ? 'الوقت' : 'Time'}: $start - $end',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: offer['active'] == true,
                    activeTrackColor: greenColor,
                    title: Text(
                      isArabic ? 'نشط' : 'Active',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onChanged: (value) => toggleOffer(id, value),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => editOffer(id, offer),
                        icon: const Icon(Icons.edit_outlined),
                        label: Text(isArabic ? 'تعديل' : 'Edit'),
                      ),
                      TextButton.icon(
                        onPressed: () => deleteOffer(id),
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        label: Text(
                          isArabic ? 'حذف' : 'Delete',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          title: Text(isArabic ? 'إدارة العروض' : 'Manage offers'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              buildForm(),
              const SizedBox(height: 22),
              sectionTitle(isArabic ? 'العروض الحالية' : 'Current offers'),
              buildOffersList(),
            ],
          ),
        ),
      ),
    );
  }
}