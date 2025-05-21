import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  bool _showCompleted = false;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _sortType = 'date'; // 'date', 'alphabetical', 'priority', 'dueDate'
  
  // UUID yerine basit bir ID generator kullanalım
  String _generateUniqueId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  void _showTaskDialog({Task? task}) {
    final focusModel = Provider.of<FocusModel>(context, listen: false);
    final isEditing = task != null;
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(text: task?.description ?? '');
    
    // Yeni kontroller ekleme
    String selectedCategory = task?.category ?? focusModel.taskCategories.first;
    int estimatedPomodoros = task?.estimatedPomodoros ?? 1;
    int priority = task?.priority ?? 2;
    DateTime? dueDate = task?.dueDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isEditing ? 'Görevi Düzenle' : 'Yeni Görev',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama (İsteğe bağlı)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Kategori seçici
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedCategory,
                  items: focusModel.taskCategories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedCategory = value;
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Tahmini pomodoro sayısı
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tahmini Pomodoro'),
                    ),
                    SizedBox(
                      width: 120,
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withAlpha(128),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (estimatedPomodoros > 1) {
                                  setState(() => estimatedPomodoros--);
                                }
                              },
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            Text(
                              '$estimatedPomodoros',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => estimatedPomodoros++);
                              },
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Öncelik seçici
                Row(
                  children: [
                    const Expanded(
                      child: Text('Öncelik'),
                    ),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment<int>(
                          value: 1,
                          label: Text('Düşük'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                        ButtonSegment<int>(
                          value: 2,
                          label: Text('Orta'),
                          icon: Icon(Icons.remove),
                        ),
                        ButtonSegment<int>(
                          value: 3,
                          label: Text('Yüksek'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                      ],
                      selected: {priority},
                      onSelectionChanged: (Set<int> newSelection) {
                        priority = newSelection.first;
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Son tarih seçici
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Son Tarih'),
                  subtitle: Text(
                    dueDate != null
                        ? DateFormat('dd.MM.yyyy').format(dueDate!) // Nullable olduğu için ! operatörü ekliyoruz
                        : 'Ayarlanmadı',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate ?? DateTime.now(),  // null ise şu anki tarihi kullan
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              dueDate = picked;
                            });
                          }
                        },
                      ),
                      if (dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              dueDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  if (isEditing) {
                    final updatedTask = Task(
                      id: task.id,  // Artık ! işaretine gerek yok çünkü task zaten null değil
                      title: title,
                      description: descriptionController.text.trim(),
                      isCompleted: task.isCompleted,
                      createdAt: task.createdAt,
                      category: selectedCategory,
                      pomodoroCount: task.pomodoroCount,
                      estimatedPomodoros: estimatedPomodoros,
                      dueDate: dueDate,
                      priority: priority,
                    );
                    focusModel.editTask(updatedTask);
                  } else {
                    final newTask = Task(
                      id: _generateUniqueId(),
                      title: title,
                      description: descriptionController.text.trim(),
                      createdAt: DateTime.now(),
                      category: selectedCategory,
                      estimatedPomodoros: estimatedPomodoros,
                      dueDate: dueDate,
                      priority: priority,
                    );
                    focusModel.addTask(newTask);
                  }
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? 'Kaydet' : 'Ekle'),
            ),
          ],
        );
      },
    );
  }

  void _showSortMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    
    // Güncellenen menü
    showMenu<String>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<String>(
          value: 'alphabetical',
          child: Text('İsim (A-Z)'),
        ),
        const PopupMenuItem<String>(
          value: 'date',
          child: Text('Oluşturma Tarihi'),
        ),
        const PopupMenuItem<String>(
          value: 'priority',
          child: Text('Öncelik'),
        ),
        const PopupMenuItem<String>(
          value: 'dueDate',
          child: Text('Son Tarih'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      setState(() {
        _sortType = value;
        // Sıralama değiştiğinde görevleri sırala
        _sortTasks(Provider.of<FocusModel>(context, listen: false).tasks);
      });
    });
  }
  
  List<Task> _sortTasks(List<Task> tasks) {
    List<Task> sortedTasks = List.from(tasks);
    
    switch (_sortType) {
      case 'alphabetical':
        sortedTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'priority':
        sortedTasks.sort((a, b) => b.priority.compareTo(a.priority));
        break;
      case 'dueDate':
        sortedTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'date':
      default:
        sortedTasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    
    return sortedTasks;
  }
  
  List<Task> _filterTasks(List<Task> tasks) {
    return tasks.where((task) {
      // Tamamlanma durumuna göre filtrele
      if (!_showCompleted && task.isCompleted) {
        return false;
      }
      
      // Arama sorgusuna göre filtrele
      if (_searchQuery.isNotEmpty && 
          !task.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !task.description.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      
      // Kategoriye göre filtrele
      if (_selectedCategory != 'Tümü' && task.category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final focusModel = Provider.of<FocusModel>(context);
    final allTasks = focusModel.tasks;
    final filteredTasks = _filterTasks(allTasks);
    final sortedTasks = _sortTasks(filteredTasks);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Kategorileri al ve "Tümü" ekle
    final List<String> categories = ['Tümü', ...focusModel.taskCategories];
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Row with additional options
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Görevler (${focusModel.tasks.length})',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      tooltip: 'Sırala',
                      onPressed: () => _showSortMenu(context),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Tamamlananları Göster',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: _showCompleted,
                      onChanged: (value) => setState(() => _showCompleted = value),
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Search Box (geliştirilmiş)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Görev ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.grey[800] 
                    : Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Kategori Seçici
          Container(
            height: 40,
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    selectedColor: colorScheme.primary.withAlpha(51),
                    labelStyle: TextStyle(
                      color: isSelected ? colorScheme.primary : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                );
              }
            ),
          ),
          
          // Task List
          Expanded(
            child: sortedTasks.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Yapılacak görevler
                      if (sortedTasks.any((t) => !t.isCompleted)) ...[
                        const Text(
                          'Yapılacaklar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sortedTasks.where((t) => !t.isCompleted).map((task) => 
                          _buildTaskItem(task, focusModel, isDarkMode)
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Tamamlanan görevler
                      if (_showCompleted && sortedTasks.any((t) => t.isCompleted)) ...[
                        const Text(
                          'Tamamlananlar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sortedTasks.where((t) => t.isCompleted).map((task) => 
                          _buildTaskItem(task, focusModel, isDarkMode)
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(),
        elevation: 2,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: "Yeni Görev Ekle",
        icon: const Icon(Icons.add),
        label: const Text('Yeni Görev'),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 56,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _showCompleted 
                ? 'Henüz tamamlanan görev yok'
                : 'Görev listeniz boş',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir görev eklemek için + butonuna tıklayın',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  // @override anotasyonunu kaldırdık
  Widget _buildTaskItem(Task task, FocusModel focusModel, bool isDarkMode) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color borderColor = isDarkMode
      ? Colors.grey.withAlpha(50)
      : Colors.grey.withAlpha(50);
    
    // Öncelik rengi
    Color getPriorityColor() {
      switch (task.priority) {
        case 1: return Colors.green;
        case 3: return Colors.red;
        default: return Colors.orange;
      }
    }
    
    // Geliştirilmiş görev öğesi
    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        color: Colors.red.shade300,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Görevi Sil'),
            content: const Text('Bu görevi silmek istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => focusModel.deleteTask(task.id),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // color: isDarkMode 
            //     ? task.isCompleted
            //         ? colorScheme.surfaceContainerHighest.withAlpha(75) // withOpacity yerine withAlpha
            //         : colorScheme.surface
            //     : task.isCompleted
            //         ? colorScheme.surfaceContainerHighest.withAlpha(75) // withOpacity yerine withAlpha
            //         : colorScheme.surface,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Öncelik göstergesi
                  Container(
                    width: 4,
                    height: 72, // ListTile'ın yaklaşık yüksekliği
                    decoration: BoxDecoration(
                      color: getPriorityColor(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => focusModel.toggleTaskCompletion(task.id),
                        shape: const CircleBorder(),
                        activeColor: colorScheme.primary,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                                color: task.isCompleted 
                                    ? isDarkMode ? Colors.grey : Colors.grey[600]
                                    : isDarkMode ? Colors.grey[100] : Colors.black87,
                              ),
                            ),
                          ),
                          
                          // Kategori rozeti
                          if (!task.isCompleted) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.description.isNotEmpty)
                            Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          
                          // Son tarih göstergesi
                          if (task.dueDate != null && !task.isCompleted)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.event, 
                                    size: 12, 
                                    color: DateTime.now().isAfter(task.dueDate!) 
                                        ? Colors.red 
                                        : isDarkMode ? Colors.grey[400] : Colors.grey[700]
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM').format(task.dueDate!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DateTime.now().isAfter(task.dueDate!) 
                                          ? Colors.red 
                                          : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _showTaskDialog(task: task);
                              break;
                            case 'delete':
                              // Show confirmation dialog
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Görevi Sil'),
                                  content: const Text('Bu görevi silmek istediğinizden emin misiniz?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        focusModel.deleteTask(task.id);
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text(
                                        'Sil',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              break;
                            case 'focus':
                              // Set as current focus task and navigate to timer
                              focusModel.setCurrentTaskIdForSession(task.id);
                              // In a real app, navigate to timer screen
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Görev zamanlayıcı için seçildi'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Düzenle'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Sil'),
                          ),
                          const PopupMenuItem(
                            value: 'focus',
                            child: Text('Bu görev üzerinde çalış'),
                          ),
                        ],
                      ),
                      onTap: () => _showTaskDialog(task: task),
                    ),
                  ),
                ],
              ),
              
              // Divider logic
              if (task.description.isNotEmpty) Divider(
                height: 1,
                indent: 70,
                endIndent: 16,
                color: colorScheme.outlineVariant,
              ),
              
              // Pomodoro ilerleme çubuğu
              if (!task.isCompleted) Container(
                margin: const EdgeInsets.only(left: 70, right: 16, bottom: 8),
                height: 4,
                child: LinearProgressIndicator(
                  value: task.completionPercentage,
                  backgroundColor: Colors.grey.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              
              // Pomodoro sayaçları
              if (!task.isCompleted) Padding(
                padding: const EdgeInsets.only(left: 70, right: 16, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.pomodoroCount}/${task.estimatedPomodoros} pomodoro',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
